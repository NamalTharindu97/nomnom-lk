package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func RequireDashboardAccess() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, exists := GetUserRole(c)
		if !exists {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"error": gin.H{
					"code":    "FORBIDDEN",
					"message": "Authentication required",
				},
			})
			return
		}

		if role != "restaurant_owner" && role != "admin" {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"error": gin.H{
					"code":    "FORBIDDEN",
					"message": "Web dashboard access restricted to restaurant owners and admins",
				},
			})
			return
		}

		c.Next()
	}
}
