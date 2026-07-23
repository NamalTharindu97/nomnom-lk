package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

const (
	BrowserAccessCookie = "nomnom_access"
	authTransportKey    = "auth_transport"
	authTransportBearer = "bearer"
	authTransportCookie = "cookie"
)

type Claims struct {
	Sub            string `json:"sub"`
	Email          string `json:"email"`
	Name           string `json:"name"`
	Role           string `json:"role"`
	ImpersonatedBy string `json:"impersonated_by,omitempty"`
	ImpersonatedAt int64  `json:"impersonated_at,omitempty"`
	jwt.RegisteredClaims
}

func Auth(jwtSecret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		tokenString := ""
		transport := authTransportBearer
		if authHeader == "" {
			tokenString, _ = c.Cookie(BrowserAccessCookie)
			transport = authTransportCookie
		}
		if tokenString == "" && authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": gin.H{
					"code":    "UNAUTHORIZED",
					"message": "Authentication required",
				},
			})
			return
		}

		if authHeader != "" {
			parts := strings.SplitN(authHeader, " ", 2)
			if len(parts) != 2 || parts[0] != "Bearer" {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
					"error": gin.H{
						"code":    "UNAUTHORIZED",
						"message": "Invalid authorization header format",
					},
				})
				return
			}
			tokenString = parts[1]
		}

		claims := &Claims{}

		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(jwtSecret), nil
		}, jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}))

		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": gin.H{
					"code":    "UNAUTHORIZED",
					"message": "Invalid or expired token",
				},
			})
			return
		}

		c.Set("user_id", claims.Sub)
		c.Set("user_email", claims.Email)
		c.Set("user_name", claims.Name)
		c.Set("user_role", claims.Role)
		c.Set("impersonated_by", claims.ImpersonatedBy)
		c.Set("impersonated_at", claims.ImpersonatedAt)
		c.Set(authTransportKey, transport)
		if transport == authTransportCookie && !validCSRF(c) {
			abortCSRF(c)
			return
		}
		c.Next()
	}
}

func IsCookieAuth(c *gin.Context) bool {
	transport, exists := c.Get(authTransportKey)
	return exists && transport == authTransportCookie
}

func GetUserID(c *gin.Context) (uuid.UUID, bool) {
	id, exists := c.Get("user_id")
	if !exists {
		return uuid.Nil, false
	}
	idStr, ok := id.(string)
	if !ok {
		return uuid.Nil, false
	}
	parsed, err := uuid.Parse(idStr)
	if err != nil {
		return uuid.Nil, false
	}
	return parsed, true
}

func GetUserEmail(c *gin.Context) (string, bool) {
	email, exists := c.Get("user_email")
	if !exists {
		return "", false
	}
	return email.(string), true
}

func GetUserName(c *gin.Context) (string, bool) {
	name, exists := c.Get("user_name")
	if !exists {
		return "", false
	}
	return name.(string), true
}

func GetUserRole(c *gin.Context) (string, bool) {
	role, exists := c.Get("user_role")
	if !exists {
		return "", false
	}
	return role.(string), true
}

func GetImpersonatedBy(c *gin.Context) (string, bool) {
	val, exists := c.Get("impersonated_by")
	if !exists {
		return "", false
	}
	str, ok := val.(string)
	return str, ok && str != ""
}

func IsImpersonating(c *gin.Context) bool {
	val, exists := c.Get("impersonated_by")
	if !exists {
		return false
	}
	str, ok := val.(string)
	return ok && str != ""
}
