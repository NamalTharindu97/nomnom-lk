package services

import (
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"github.com/nomnom-lk/backend/internal/config"
)

type UploadService struct {
	client *minio.Client
	bucket string
	prefix string
}

func NewUploadService(cfg *config.AWSConfig) (*UploadService, error) {
	client, err := minio.New(cfg.S3Endpoint, &minio.Options{
		Creds:        credentials.NewStaticV4(cfg.AccessKeyID, cfg.SecretAccessKey, ""),
		Secure:       false,
		Region:       cfg.Region,
		BucketLookup: minio.BucketLookupAuto,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create minio client: %w", err)
	}

	ctx := context.Background()
	exists, err := client.BucketExists(ctx, cfg.S3Bucket)
	if err != nil {
		return nil, fmt.Errorf("failed to check bucket: %w", err)
	}

	if !exists {
		if err := client.MakeBucket(ctx, cfg.S3Bucket, minio.MakeBucketOptions{
			Region: cfg.Region,
		}); err != nil {
			return nil, fmt.Errorf("failed to create bucket: %w", err)
		}
	}

	env := "dev"
	prefix := env

	return &UploadService{
		client: client,
		bucket: cfg.S3Bucket,
		prefix: prefix,
	}, nil
}

func (s *UploadService) UploadSingle(file *multipart.FileHeader, folder string) (string, error) {
	src, err := file.Open()
	if err != nil {
		return "", fmt.Errorf("failed to open file: %w", err)
	}
	defer src.Close()

	ext := strings.ToLower(filepath.Ext(file.Filename))
	objectKey := fmt.Sprintf("%s/%s/%s%s", s.prefix, folder, uuid.New().String(), ext)

	contentType := file.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	ctx := context.Background()
	_, err = s.client.PutObject(ctx, s.bucket, objectKey, src, file.Size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload file: %w", err)
	}

	url := fmt.Sprintf("/api/v1/uploads/%s", objectKey)
	return url, nil
}

func (s *UploadService) UploadReader(reader io.Reader, size int64, filename, folder string) (string, error) {
	ext := strings.ToLower(filepath.Ext(filename))
	objectKey := fmt.Sprintf("%s/%s/%s%s", s.prefix, folder, uuid.New().String(), ext)

	contentType := "image/jpeg"
	switch ext {
	case ".png":
		contentType = "image/png"
	case ".gif":
		contentType = "image/gif"
	case ".webp":
		contentType = "image/webp"
	case ".svg":
		contentType = "image/svg+xml"
	}

	ctx := context.Background()
	_, err := s.client.PutObject(ctx, s.bucket, objectKey, reader, size, minio.PutObjectOptions{
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
