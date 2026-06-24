package router

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"gorm.io/gorm"

	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/middleware"
)

func SetupRouter(cfg *config.Config, db *gorm.DB, rdb *redis.Client, log zerolog.Logger) *gin.Engine {
	r := gin.New()

	r.Use(
		middleware.RequestID(),
		middleware.Logger(log),
		middleware.Recovery(log),
		middleware.CORS(cfg.CORS.Origins),
		middleware.Localization(),
	)

	r.GET("/health", func(c *gin.Context) {
		sqlDB, _ := db.DB()
		dbErr := sqlDB.Ping()

		redisErr := rdb.Ping(c.Request.Context()).Err()

		status := "ok"
		if dbErr != nil || redisErr != nil {
			status = "degraded"
		}

		c.JSON(200, gin.H{
			"status":   status,
			"version":  "1.0.0",
			"uptime":   "",
			"database": map[string]interface{}{"status": errStr(dbErr)},
			"redis":    map[string]interface{}{"status": errStr(redisErr)},
		})
	})

	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	v1 := r.Group("/api/v1")
	{
		authGroup := v1.Group("/auth")
		authGroup.Use(middleware.RateLimit(rdb, 20, 1*time.Minute, "rl:auth"))
		{
			_ = authGroup
		}

		usersGroup := v1.Group("/users")
		usersGroup.Use(middleware.Auth(cfg.JWT.Secret))
		{
			_ = usersGroup
		}

		restaurantsGroup := v1.Group("/restaurants")
		{
			_ = restaurantsGroup
		}

		offersGroup := v1.Group("/offers")
		{
			_ = offersGroup
		}

		favoritesGroup := v1.Group("/favorites")
		favoritesGroup.Use(middleware.Auth(cfg.JWT.Secret))
		{
			_ = favoritesGroup
		}

		v1.GET("/search", func(c *gin.Context) {
			c.JSON(200, gin.H{"data": []interface{}{}, "pagination": gin.H{}})
		})

		uploadGroup := v1.Group("/upload")
		uploadGroup.Use(middleware.Auth(cfg.JWT.Secret))
		uploadGroup.Use(middleware.RateLimit(rdb, 10, 1*time.Minute, "rl:upload"))
		{
			_ = uploadGroup
		}

		notificationsGroup := v1.Group("/notifications")
		notificationsGroup.Use(middleware.Auth(cfg.JWT.Secret))
		{
			_ = notificationsGroup
		}

		devicesGroup := v1.Group("/devices")
		devicesGroup.Use(middleware.Auth(cfg.JWT.Secret))
		{
			_ = devicesGroup
		}

		adminGroup := v1.Group("/admin")
		adminGroup.Use(middleware.Auth(cfg.JWT.Secret))
		adminGroup.Use(middleware.RequireRole("admin"))
		{
			_ = adminGroup
		}
	}

	return r
}

func errStr(err error) string {
	if err != nil {
		return "disconnected"
	}
	return "connected"
}
