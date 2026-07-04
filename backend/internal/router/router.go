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
	"github.com/nomnom-lk/backend/internal/handlers"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/internal/services"
)

func SetupRouter(cfg *config.Config, db *gorm.DB, rdb *redis.Client, log zerolog.Logger) (*gin.Engine, *services.CronService) {
	// Repositories
	userRepo := repository.NewUserRepo(db)
	refreshTokenRepo := repository.NewRefreshTokenRepo(db)
	restaurantRepo := repository.NewRestaurantRepo(db)
	offerRepo := repository.NewOfferRepo(db)
	favoriteRepo := repository.NewFavoriteRepo(db)
	deviceTokenRepo := repository.NewDeviceTokenRepo(db)
	notificationRepo := repository.NewNotificationRepo(db)
	auditLogRepo := repository.NewAuditLogRepo(db)

	// Services
	sseService := services.NewSSEService()
	emailService := services.NewEmailService(&cfg.SMTP, log)
	authService := services.NewAuthService(userRepo, refreshTokenRepo, &cfg.JWT, rdb, emailService)
	restaurantService := services.NewRestaurantService(restaurantRepo)
	offerService := services.NewOfferService(offerRepo, restaurantRepo)
	favoriteService := services.NewFavoriteService(favoriteRepo)
	searchService := services.NewSearchService(db)
	notificationService := services.NewNotificationService(notificationRepo, deviceTokenRepo, &cfg.Firebase)
	cronService := services.NewCronService(db, notificationService, notificationRepo)

	uploadService, err := services.NewUploadService(&cfg.AWS)
	if err != nil {
		log.Warn().Err(err).Msg("upload service not available, upload routes disabled")
		uploadService = nil
	}

	// Handlers
	firebaseService := services.NewFirebaseService(&cfg.Firebase)
	authHandler := handlers.NewAuthHandler(authService, firebaseService)
	userHandler := handlers.NewUserHandler(userRepo)
	adminHandler := handlers.NewAdminHandler(restaurantRepo, offerRepo, userRepo, notificationRepo)
	restaurantHandler := handlers.NewRestaurantHandler(restaurantService, sseService)
	offerHandler := handlers.NewOfferHandler(offerService, sseService)
	favoriteHandler := handlers.NewFavoriteHandler(favoriteService, sseService)
	searchHandler := handlers.NewSearchHandler(searchService)
	notificationHandler := handlers.NewNotificationHandler(notificationService)
	auditLogHandler := handlers.NewAuditLogHandler(auditLogRepo)
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
		v1.GET("/events", sseService.HandleSSE)
		authGroup := v1.Group("/auth")
		authGroup.Use(middleware.RateLimit(rdb, 20, 1*time.Minute, "rl:auth"))
		{
			authGroup.POST("/register", authHandler.Register)
			authGroup.POST("/login", authHandler.Login)
			authGroup.POST("/firebase", authHandler.FirebaseLogin)
			authGroup.POST("/refresh", authHandler.Refresh)
			authGroup.POST("/logout", middleware.Auth(cfg.JWT.Secret), authHandler.Logout)
		}

		verificationGroup := v1.Group("/auth")
		verificationGroup.Use(middleware.RateLimit(rdb, 3, 1*time.Minute, "rl:verify"))
		{
			verificationGroup.POST("/send-verification", authHandler.SendVerification)
			verificationGroup.POST("/verify-email", authHandler.VerifyEmail)
		}

		usersGroup := v1.Group("/users")
		usersGroup.Use(middleware.Auth(cfg.JWT.Secret))
		{
			usersGroup.GET("/me", userHandler.Me)
			usersGroup.POST("/me/change-password", userHandler.ChangePassword)
		}

		adminUsers := usersGroup.Group("")
		adminUsers.Use(middleware.RequireRole("admin"))
		{
			adminUsers.GET("", userHandler.List)
			adminUsers.POST("", userHandler.Create)
			adminUsers.PUT("/:id", userHandler.Update)
			adminUsers.DELETE("/:id", userHandler.Delete)
		}

		restaurantsGroup := v1.Group("/restaurants")
		{
			restaurantsGroup.GET("", restaurantHandler.List)
			restaurantsGroup.GET("/:id", restaurantHandler.Get)
			restaurantsGroup.POST("", middleware.Auth(cfg.JWT.Secret), restaurantHandler.Create)
			restaurantsGroup.PUT("/:id", middleware.Auth(cfg.JWT.Secret), restaurantHandler.Update)
			restaurantsGroup.DELETE("/:id", middleware.Auth(cfg.JWT.Secret), restaurantHandler.Delete)
			restaurantsGroup.POST("/:id/approve", middleware.Auth(cfg.JWT.Secret), middleware.RequireRole("admin"), restaurantHandler.Approve)
			restaurantsGroup.POST("/:id/reject", middleware.Auth(cfg.JWT.Secret), middleware.RequireRole("admin"), restaurantHandler.Reject)
		}

		offersGroup := v1.Group("/offers")
		{
			offersGroup.GET("", offerHandler.List)
			offersGroup.GET("/:id", offerHandler.Get)
			offersGroup.POST("", middleware.Auth(cfg.JWT.Secret), offerHandler.Create)
			offersGroup.PUT("/:id", middleware.Auth(cfg.JWT.Secret), offerHandler.Update)
			offersGroup.DELETE("/:id", middleware.Auth(cfg.JWT.Secret), offerHandler.Delete)
			offersGroup.POST("/:id/approve", middleware.Auth(cfg.JWT.Secret), middleware.RequireRole("admin"), offerHandler.Approve)
			offersGroup.POST("/:id/reject", middleware.Auth(cfg.JWT.Secret), middleware.RequireRole("admin"), offerHandler.Reject)
		}

		favoritesGroup := v1.Group("/favorites")
		favoritesGroup.Use(middleware.Auth(cfg.JWT.Secret))
		{
			favoritesGroup.GET("", favoriteHandler.List)
			favoritesGroup.POST("", favoriteHandler.Add)
			favoritesGroup.DELETE("/:offerId", favoriteHandler.Remove)
		}

		v1.GET("/search", searchHandler.Search)

		var uploadHandler *handlers.UploadHandler
		if uploadService != nil {
			uploadHandler = handlers.NewUploadHandler(uploadService)
			uploadGroup := v1.Group("/upload")
			uploadGroup.Use(middleware.Auth(cfg.JWT.Secret))
			uploadGroup.Use(middleware.RateLimit(rdb, 10, 1*time.Minute, "rl:upload"))
			{
				uploadGroup.POST("", uploadHandler.Upload)
				uploadGroup.POST("/multiple", uploadHandler.UploadMultiple)
			}

			v1.GET("/uploads/*key", uploadHandler.ServeFile)
		}

		notificationsGroup := v1.Group("/notifications")
		notificationsGroup.Use(middleware.Auth(cfg.JWT.Secret))
		{
			notificationsGroup.GET("", notificationHandler.List)
			notificationsGroup.GET("/unread-count", notificationHandler.UnreadCount)
			notificationsGroup.PUT("/:id/read", notificationHandler.MarkAsRead)
			notificationsGroup.PUT("/read-all", notificationHandler.MarkAllAsRead)
		}

		devicesGroup := v1.Group("/devices")
		devicesGroup.Use(middleware.Auth(cfg.JWT.Secret))
		{
			devicesGroup.POST("", notificationHandler.RegisterDevice)
			devicesGroup.DELETE("", notificationHandler.UnregisterDevice)
		}

		adminGroup := v1.Group("/admin")
		adminGroup.Use(middleware.Auth(cfg.JWT.Secret))
		adminGroup.Use(middleware.RequireRole("admin"))
		{
			adminGroup.GET("/stats", adminHandler.Stats)
			adminGroup.GET("/stats/timeline", adminHandler.StatsTimeline)
			adminGroup.GET("/notifications", adminHandler.ListNotifications)
			adminGroup.POST("/notifications/push", notificationHandler.SendPush)
			adminGroup.GET("/audit-log", auditLogHandler.List)
		}
	}

	return r, cronService
}

func errStr(err error) string {
	if err != nil {
		return "disconnected"
	}
	return "connected"
}
