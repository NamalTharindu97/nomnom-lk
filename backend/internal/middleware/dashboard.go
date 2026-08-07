package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/nomnom-lk/backend/internal/models"
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

		if role != string(models.RoleRestaurantOwner) && role != string(models.RoleAdmin) && role != string(models.RolePortfolioViewer) {
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
