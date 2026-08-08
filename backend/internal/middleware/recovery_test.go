package middleware

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"github.com/stretchr/testify/require"
)

func TestRecoveryLogsSafeRequestDiagnostics(t *testing.T) {
	gin.SetMode(gin.TestMode)

	var output bytes.Buffer
	log := zerolog.New(&output)
	router := gin.New()
	router.Use(RequestID(), Recovery(log))
	router.GET("/panic/:id", func(c *gin.Context) {
		panic("test panic")
	})

	recorder := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/panic/private-resource?access_token=private-token", nil)
	router.ServeHTTP(recorder, request)

	require.Equal(t, http.StatusInternalServerError, recorder.Code)
	require.NotEmpty(t, recorder.Header().Get("X-Request-ID"))
	require.NotContains(t, recorder.Body.String(), "test panic")
	require.NotContains(t, recorder.Body.String(), "private-token")

	var entry map[string]any
	require.NoError(t, json.Unmarshal(output.Bytes(), &entry))
	require.Equal(t, "error", entry["level"])
	require.Equal(t, "panic recovered", entry["message"])
	require.Equal(t, http.MethodGet, entry["method"])
	require.Equal(t, "/panic/:id", entry["path"])
	require.Equal(t, "test panic", entry["panic"])
	require.NotEmpty(t, entry["request_id"])
	require.Contains(t, entry["stack"], "TestRecoveryLogsSafeRequestDiagnostics")
	require.NotContains(t, output.String(), "private-token")
	require.NotContains(t, output.String(), "private-resource")
}
