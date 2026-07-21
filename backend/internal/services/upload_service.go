package services

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"github.com/disintegration/imaging"
	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"github.com/nomnom-lk/backend/internal/config"
)

const (
	cropWidth     = 1024
	cropHeight    = 1024
	avatarWidth   = 256
	avatarHeight  = 256
	bannerWidth   = 1024
	bannerHeight  = 360
)

func cropSizeForFolder(folder string) (int, int) {
	switch folder {
	case "avatars":
		return avatarWidth, avatarHeight
	case "banners":
		return bannerWidth, bannerHeight
	default:
		return cropWidth, cropHeight
	}
}

type UploadService struct {
	client *minio.Client
	bucket string
	prefix string
}

func NewUploadService(cfg *config.R2Config) (*UploadService, error) {
	lookupType := minio.BucketLookupAuto
	if cfg.ForcePathStyle {
		lookupType = minio.BucketLookupPath
	}
	client, err := minio.New(cfg.Endpoint, &minio.Options{
		Creds:        credentials.NewStaticV4(cfg.AccessKeyID, cfg.SecretAccessKey, ""),
		Secure:       cfg.Secure,
		Region:       cfg.Region,
		BucketLookup: lookupType,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create minio client: %w", err)
	}

	ctx := context.Background()
	exists, err := client.BucketExists(ctx, cfg.Bucket)
	if err != nil {
		return nil, fmt.Errorf("failed to check bucket: %w", err)
	}

	if !exists {
		if err := client.MakeBucket(ctx, cfg.Bucket, minio.MakeBucketOptions{
			Region: cfg.Region,
		}); err != nil {
			return nil, fmt.Errorf("failed to create bucket: %w", err)
		}
	}

	prefix := cfg.Prefix
	if prefix == "" {
		prefix = "dev"
	}

	return &UploadService{
		client: client,
		bucket: cfg.Bucket,
		prefix: prefix,
	}, nil
}

func (s *UploadService) UploadSingle(file *multipart.FileHeader, folder string) (string, error) {
	src, err := file.Open()
	if err != nil {
		return "", fmt.Errorf("failed to open file: %w", err)
	}
	defer src.Close()

	data, err := io.ReadAll(src)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	w, h := cropSizeForFolder(folder)
	return s.uploadCropped(data, ext, folder, w, h)
}

func (s *UploadService) UploadReader(reader io.Reader, size int64, filename, folder string) (string, error) {
	data, err := io.ReadAll(reader)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	ext := strings.ToLower(filepath.Ext(filename))
	w, h := cropSizeForFolder(folder)
	return s.uploadCropped(data, ext, folder, w, h)
}

func (s *UploadService) uploadCropped(data []byte, ext, folder string, cropW, cropH int) (string, error) {
	objectKey := fmt.Sprintf("%s/%s/%s.jpg", s.prefix, folder, uuid.New().String())

	var uploadData []byte
	var contentType string

	if ext == ".svg" {
		objectKey = fmt.Sprintf("%s/%s/%s.svg", s.prefix, folder, uuid.New().String())
		uploadData = data
		contentType = "image/svg+xml"
	} else {
		img, err := imaging.Decode(bytes.NewReader(data))
		if err != nil {
			return "", fmt.Errorf("failed to decode image: %w", err)
		}
		cropped := imaging.Fill(img, cropW, cropH, imaging.Center, imaging.Lanczos)
		buf := new(bytes.Buffer)
		if err := imaging.Encode(buf, cropped, imaging.JPEG, imaging.JPEGQuality(60)); err != nil {
			return "", fmt.Errorf("failed to encode image: %w", err)
		}
		uploadData = buf.Bytes()
		contentType = "image/jpeg"
	}

	ctx := context.Background()
	_, err := s.client.PutObject(ctx, s.bucket, objectKey, bytes.NewReader(uploadData), int64(len(uploadData)), minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload file: %w", err)
	}

	url := fmt.Sprintf("/api/v1/uploads/%s", objectKey)
	return url, nil
}

func (s *UploadService) UploadMultiple(files []*multipart.FileHeader, folder string) ([]string, error) {
	urls := make([]string, 0, len(files))
	for _, file := range files {
		url, err := s.UploadSingle(file, folder)
		if err != nil {
			return urls, err
		}
		urls = append(urls, url)
	}
	return urls, nil
}

func (s *UploadService) Delete(key string) error {
	ctx := context.Background()
	return s.client.RemoveObject(ctx, s.bucket, key, minio.RemoveObjectOptions{})
}

func (s *UploadService) PresignedURL(key string, expiry time.Duration) (string, error) {
	ctx := context.Background()
	url, err := s.client.PresignedGetObject(ctx, s.bucket, key, expiry, nil)
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned url: %w", err)
	}
	return url.String(), nil
}

func (s *UploadService) GetFile(key string) (io.ReadCloser, string, error) {
	ctx := context.Background()
	object, err := s.client.GetObject(ctx, s.bucket, key, minio.GetObjectOptions{})
	if err != nil {
		return nil, "", fmt.Errorf("failed to get file: %w", err)
	}

	stat, err := object.Stat()
	if err != nil {
		object.Close()
		return nil, "", fmt.Errorf("file not found: %w", err)
	}

	return object, stat.ContentType, nil
}

func (s *UploadService) ListObjects(folder string) ([]string, error) {
	ctx := context.Background()
	prefix := fmt.Sprintf("%s/%s/", s.prefix, folder)

	objects := s.client.ListObjects(ctx, s.bucket, minio.ListObjectsOptions{
		Prefix: prefix,
	})

	var urls []string
	for obj := range objects {
		if obj.Err != nil {
			return nil, obj.Err
		}
		urls = append(urls, fmt.Sprintf("/api/v1/uploads/%s/%s", s.prefix, obj.Key))
	}

	return urls, nil
}

func AllowedExtensions() map[string]bool {
	return map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".gif":  true,
		".webp": true,
		".svg":  true,
	}
}

func MaxFileSize() int64 {
	return 5 * 1024 * 1024 // 5MB
}
