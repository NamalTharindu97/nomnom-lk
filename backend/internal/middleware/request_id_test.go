package middleware

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
)

func TestRequestID(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name       string
		header     string
		wantHeader string
		wantNewID  bool
	}{
		{name: "preserves safe caller identifier", header: "mobile-request_123", wantHeader: "mobile-request_123"},
		{name: "trims safe caller identifier", header: "  trace:abc-123  ", wantHeader: "trace:abc-123"},
		{name: "generates identifier when absent", wantNewID: true},
		{name: "rejects log control characters", header: "unsafe\nrequest", wantNewID: true},
		{name: "rejects oversized identifier", header: strings.Repeat("a", 129), wantNewID: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			router := gin.New()
			router.Use(RequestID())
			router.GET("/health", func(c *gin.Context) {
				c.Status(http.StatusOK)
			})

			recorder := httptest.NewRecorder()
			request := httptest.NewRequest(http.MethodGet, "/health", nil)
			if tt.header != "" {
				request.Header.Set("X-Request-ID", tt.header)
			}
			router.ServeHTTP(recorder, request)

			got := recorder.Header().Get("X-Request-ID")
			if tt.wantNewID {
				require.NotEqual(t, tt.header, got)
				require.NoError(t, uuid.Validate(got))
				return
			}
			require.Equal(t, tt.wantHeader, got)
		})
	}
}
