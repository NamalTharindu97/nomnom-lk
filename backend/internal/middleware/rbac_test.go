package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func setRole(role string) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Set("user_role", role)
		c.Set("user_id", uuid.New().String())
		c.Next()
	}
}

func TestRequireDashboardAccess_AdminAllowed(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(setRole("admin"), RequireDashboardAccess())
	r.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestRequireDashboardAccess_OwnerAllowed(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(setRole("restaurant_owner"), RequireDashboardAccess())
	r.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestRequireDashboardAccess_UserBlocked(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(setRole("user"), RequireDashboardAccess())
	r.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestOwnerScoped_Admin_NoScope(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(func(c *gin.Context) {
		c.Set("user_id", "00000000-0000-0000-0000-000000000002")
		c.Set("user_role", "admin")
		c.Next()
	})
	r.Use(OwnerScoped())
	r.GET("/test", func(c *gin.Context) {
		_, exists := c.Get("owner_scope_id")
		assert.False(t, exists, "admin should not have owner_scope_id set")
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestOwnerScoped_Owner_HasScope(t *testing.T) {
	ownerID := "00000000-0000-0000-0000-000000000003"
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(func(c *gin.Context) {
		c.Set("user_id", ownerID)
		c.Set("user_role", "restaurant_owner")
		c.Next()
	})
	r.Use(OwnerScoped())
	r.GET("/test", func(c *gin.Context) {
		id, exists := c.Get("owner_scope_id")
		assert.True(t, exists, "owner should have owner_scope_id set")
		assert.Equal(t, uuid.MustParse(ownerID), id)
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
}
