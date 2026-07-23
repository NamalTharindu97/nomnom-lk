package services

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestParseFCMErrorPreservesStaleTokenDetection(t *testing.T) {
	for _, message := range []string{"NotRegistered", "Unregistered", "UNREGISTERED"} {
		t.Run(message, func(t *testing.T) {
			status, stale := parseFCMError([]byte(`{"error":{"message":"` + message + `","status":"NOT_FOUND"}}`))
			require.Equal(t, "NOT_FOUND", status)
			require.True(t, stale)
		})
	}
}

func TestParseFCMErrorDoesNotReturnMessageContent(t *testing.T) {
	status, stale := parseFCMError([]byte(`{"error":{"message":"private notification content","status":"INVALID_ARGUMENT"}}`))
	require.Equal(t, "INVALID_ARGUMENT", status)
	require.False(t, stale)
}

func TestParseFCMErrorHandlesInvalidResponse(t *testing.T) {
	status, stale := parseFCMError([]byte("not-json"))
	require.Equal(t, "unknown", status)
	require.False(t, stale)
}
