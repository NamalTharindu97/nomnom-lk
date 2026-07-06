package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/nomnom-lk/backend/internal/repository"
)

func RequireActive(userRepo *repository.UserRepo) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := GetUserID(c)
		if !exists {
			c.Next()
			return
		}

		user, err := userRepo.FindByID(userID)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": gin.H{
					"code":    "UNAUTHORIZED",
					"message": "User not found",
				},
			})
			return
		}

		if !user.IsActive {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"error": gin.H{
					"code":    "ACCOUNT_SUSPENDED",
					"message": "Your account has been suspended. Contact an administrator.",
				},
			})
			return
		}

		c.Next()
	}
}
