package middleware

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestSanitizeQueryRedactsSensitiveValues(t *testing.T) {
	const sentinel = "private-value-that-must-not-appear"
	query := "page=2&search=rice&access_token=" + sentinel +
		"&verification_code=" + sentinel + "&api_key=" + sentinel

	result := sanitizeQuery(query)

	require.Contains(t, result, "page=2")
	require.Contains(t, result, "search=rice")
	require.NotContains(t, result, sentinel)
	require.Contains(t, result, "%5BREDACTED%5D")
}

func TestSanitizeQueryOmitsMalformedInput(t *testing.T) {
	result := sanitizeQuery("refresh_token=%zz-private")
	require.Equal(t, "[invalid query omitted]", result)
	require.NotContains(t, result, "private")
}

func TestSanitizeQueryPreservesEmptyInput(t *testing.T) {
	require.Empty(t, sanitizeQuery(""))
}
