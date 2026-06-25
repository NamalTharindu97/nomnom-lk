package handlers

import (
	"io"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/pkg/response"
)

type UploadHandler struct {
	service *services.UploadService
}

func NewUploadHandler(service *services.UploadService) *UploadHandler {
	return &UploadHandler{service: service}
}

func (h *UploadHandler) ServeFile(c *gin.Context) {
	key := c.Param("key")
	if key == "" {
		response.NotFound(c, "file not found")
		return
	}

	reader, contentType, err := h.service.GetFile(key)
	if err != nil {
		response.NotFound(c, "file not found")
		return
	}
	defer reader.Close()

	c.Header("Content-Type", contentType)
	c.Header("Cache-Control", "public, max-age=31536000")
	c.Status(http.StatusOK)
	io.Copy(c.Writer, reader)
}

func (h *UploadHandler) Upload(c *gin.Context) {
	file, err := c.FormFile("file")
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "file", Message: "file is required"},
		})
		return
	}

	if file.Size > services.MaxFileSize() {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "file", Message: "file must be less than 5MB"},
		})
		return
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	allowed := services.AllowedExtensions()
	if !allowed[ext] {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "file", Message: "file type not allowed (jpg, jpeg, png, gif, webp, svg only)"},
		})
		return
	}

	folder := c.DefaultQuery("folder", "images")
	url, err := h.service.UploadSingle(file, folder)
	if err != nil {
		response.InternalError(c, "failed to upload file")
		return
	}

	response.Success(c, gin.H{
		"url": url,
	})
}

func (h *UploadHandler) UploadMultiple(c *gin.Context) {
	form, err := c.MultipartForm()
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "files", Message: "files are required"},
		})
		return
	}

	files := form.File["files"]
	if len(files) == 0 {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "files", Message: "at least one file is required"},
		})
		return
	}

	maxSize := services.MaxFileSize()
	allowed := services.AllowedExtensions()

	for _, file := range files {
		if file.Size > maxSize {
			response.ValidationError(c, []response.ErrorDetail{
				{Field: "files", Message: "each file must be less than 5MB"},
			})
			return
		}

		ext := strings.ToLower(filepath.Ext(file.Filename))
		if !allowed[ext] {
			response.ValidationError(c, []response.ErrorDetail{
				{Field: "files", Message: "file type not allowed: " + file.Filename},
			})
			return
		}
	}

	folder := c.DefaultQuery("folder", "images")
	urls, err := h.service.UploadMultiple(files, folder)
	if err != nil {
		response.InternalError(c, "failed to upload files")
		return
	}

	response.Success(c, gin.H{
		"urls": urls,
	})
}
