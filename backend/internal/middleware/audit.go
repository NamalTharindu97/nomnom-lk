package middleware

import (
	"fmt"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/services"
)

func AuditTrail(auditService *services.AuditService) gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.Method == "GET" {
			c.Next()
			return
		}

		c.Next()

		userID, _ := GetUserID(c)
		if userID == uuid.Nil {
			return
		}

		userName, _ := GetUserName(c)
		if userName == "" {
			userName, _ = GetUserEmail(c)
		}

		path := c.Request.URL.Path
		action := c.Request.Method + "." + simplifyPath(path)
		entityType := deriveEntityType(path)
		entityID := c.Param("id")
		status := c.Writer.Status()

		userRole, _ := GetUserRole(c)
		auditService.LogAction(userID, userName, userRole, action, entityType, entityID,
			fmt.Sprintf("HTTP %d: %s %s", status, c.Request.Method, path))
	}
}

func simplifyPath(path string) string {
	trimmed := strings.TrimPrefix(path, "/api/v1")
	trimmed = strings.TrimPrefix(trimmed, "/admin")
	trimmed = strings.TrimPrefix(trimmed, "/dashboard")
	trimmed = strings.Trim(trimmed, "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) == 0 {
		return "unknown"
	}
	return strings.Join(parts, "/")
}

func deriveEntityType(path string) string {
	trimmed := strings.TrimPrefix(path, "/api/v1")
	trimmed = strings.TrimPrefix(trimmed, "/admin")
	trimmed = strings.TrimPrefix(trimmed, "/dashboard")
	trimmed = strings.Trim(trimmed, "/")
	parts := strings.Split(trimmed, "/")
	if len(parts) == 0 {
		return "unknown"
	}
	base := parts[0]
	switch base {
	case "restaurants":
		return "restaurant"
	case "offers":
		return "offer"
	case "users":
		return "user"
	case "notifications":
		return "notification"
	case "coupons":
		return "coupon"
	case "categories":
		return "category"
	case "notification-templates":
		return "template"
	case "notification-analytics":
		return "notification"
	case "impersonate":
		return "user"
	default:
		return base
	}
}
