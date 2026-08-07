package models

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestUserRoleIsAdminAssignable(t *testing.T) {
	tests := []struct {
		name string
		role UserRole
		want bool
	}{
		{name: "consumer", role: RoleUser, want: true},
		{name: "restaurant owner", role: RoleRestaurantOwner, want: true},
		{name: "admin", role: RoleAdmin, want: true},
		{name: "portfolio viewer", role: RolePortfolioViewer, want: false},
		{name: "unknown", role: UserRole("unknown"), want: false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			require.Equal(t, tt.want, tt.role.IsAdminAssignable())
		})
	}
}
