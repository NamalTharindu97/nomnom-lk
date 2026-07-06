package middleware

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func OwnerScoped() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, _ := GetUserRole(c)
		userID, _ := GetUserID(c)

		if role == "restaurant_owner" {
			c.Set("owner_scope_id", userID)
		}

		c.Next()
	}
}

func GetOwnerScopeID(c *gin.Context) (uuid.UUID, bool) {
	id, exists := c.Get("owner_scope_id")
	if !exists {
		return uuid.Nil, false
	}
	return id.(uuid.UUID), true
}
