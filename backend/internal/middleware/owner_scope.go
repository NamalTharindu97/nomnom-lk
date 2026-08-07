package middleware

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
)

type DashboardScope string

const (
	DashboardScopeOwner             DashboardScope = "owner"
	DashboardScopePlatform          DashboardScope = "platform"
	DashboardScopePortfolioPlatform DashboardScope = "portfolio_platform"
)

func OwnerScoped() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, _ := GetUserRole(c)
		userID, _ := GetUserID(c)

		switch role {
		case string(models.RoleRestaurantOwner):
			c.Set("owner_scope_id", userID)
			c.Set("dashboard_scope", DashboardScopeOwner)
		case string(models.RolePortfolioViewer):
			c.Set("dashboard_scope", DashboardScopePortfolioPlatform)
		default:
			c.Set("dashboard_scope", DashboardScopePlatform)
		}

		c.Next()
	}
}

func GetDashboardScope(c *gin.Context) (DashboardScope, bool) {
	scope, exists := c.Get("dashboard_scope")
	if !exists {
		return "", false
	}
	value, ok := scope.(DashboardScope)
	return value, ok
}

// GetDashboardOwnerID resolves the explicit dashboard scope into the repository convention.
func GetDashboardOwnerID(c *gin.Context) (uuid.UUID, bool) {
	scope, exists := GetDashboardScope(c)
	if !exists {
		return uuid.Nil, false
	}
	if scope == DashboardScopeOwner {
		return GetOwnerScopeID(c)
	}
	if scope == DashboardScopePlatform || scope == DashboardScopePortfolioPlatform {
		return uuid.Nil, true
	}
	return uuid.Nil, false
}

func IsPortfolioViewer(c *gin.Context) bool {
	role, _ := GetUserRole(c)
	return role == string(models.RolePortfolioViewer)
}

func GetOwnerScopeID(c *gin.Context) (uuid.UUID, bool) {
	id, exists := c.Get("owner_scope_id")
	if !exists {
		return uuid.Nil, false
	}
	return id.(uuid.UUID), true
}
