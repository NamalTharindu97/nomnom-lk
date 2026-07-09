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
	"github.com/nomnom-lk/backend/pkg/response"
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
	templateRepo := repository.NewNotificationTemplateRepo(db)
	scheduledNotificationRepo := repository.NewScheduledNotificationRepo(db)
	couponRepo := repository.NewCouponRepo(db)
	categoryRepo := repository.NewCategoryRepo(db)

	// Services
	auditService := services.NewAuditService(auditLogRepo)
	sseService := services.NewSSEService()
	emailService := services.NewEmailService(&cfg.SMTP, log)
	authService := services.NewAuthService(userRepo, refreshTokenRepo, &cfg.JWT, rdb, emailService)
	restaurantService := services.NewRestaurantService(restaurantRepo)
	offerService := services.NewOfferService(offerRepo, restaurantRepo, rdb)
	favoriteService := services.NewFavoriteService(favoriteRepo)
	searchService := services.NewSearchService(db)
	notificationService := services.NewNotificationService(notificationRepo, deviceTokenRepo, &cfg.Firebase)
	cronService := services.NewCronService(db, notificationService, notificationRepo)
	cronService.SetScheduledRepo(scheduledNotificationRepo)
	cronService.SetAuditLogRepo(auditLogRepo)

	uploadService, err := services.NewUploadService(&cfg.R2)
	if err != nil {
		log.Warn().Err(err).Msg("upload service not available, upload routes disabled")
		uploadService = nil
	}

	// Handlers
	firebaseService := services.NewFirebaseService(&cfg.Firebase)
	authHandler := handlers.NewAuthHandler(authService, firebaseService, auditService)
	userHandler := handlers.NewUserHandler(userRepo, auditService)
	dashboardService := services.NewDashboardService(restaurantRepo, offerRepo, rdb)
	dashboardHandler := handlers.NewDashboardHandler(dashboardService, sseService, auditService)
	adminHandler := handlers.NewAdminHandler(restaurantRepo, offerRepo, userRepo, notificationRepo, auditService)
	restaurantHandler := handlers.NewRestaurantHandler(restaurantService, sseService, auditService)
	offerHandler := handlers.NewOfferHandler(offerService, sseService, auditService)
	favoriteHandler := handlers.NewFavoriteHandler(favoriteService, sseService)
	searchHandler := handlers.NewSearchHandler(searchService)
	notificationHandler := handlers.NewNotificationHandler(notificationService, auditService)
	notificationHandler.SetScheduledRepo(scheduledNotificationRepo)
	templateHandler := handlers.NewTemplateHandler(templateRepo)
	couponHandler := handlers.NewCouponHandler(couponRepo)
	categoryHandler := handlers.NewCategoryHandler(categoryRepo)
	auditLogHandler := handlers.NewAuditLogHandler(auditLogRepo)
	impersonationService := services.NewImpersonationService(userRepo, &cfg.JWT, rdb, auditService)
	impersonationHandler := handlers.NewImpersonationHandler(impersonationService)
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
			authGroup.POST("/logout", middleware.Auth(cfg.JWT.Secret), middleware.AuditTrail(auditService), authHandler.Logout)
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
			usersGroup.PUT("/me/profile", userHandler.UpdateProfile)
		}

		adminUsers := usersGroup.Group("")
		adminUsers.Use(middleware.RequireRole("admin"))
		adminUsers.Use(middleware.AuditTrail(auditService))
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
			restaurantsAuth := restaurantsGroup.Group("")
			restaurantsAuth.Use(middleware.Auth(cfg.JWT.Secret))
			restaurantsAuth.Use(middleware.AuditTrail(auditService))
			{
				restaurantsAuth.POST("", restaurantHandler.Create)
				restaurantsAuth.PUT("/:id", restaurantHandler.Update)
				restaurantsAuth.DELETE("/:id", restaurantHandler.Delete)
				restaurantsAuth.POST("/:id/approve", middleware.RequireRole("admin"), restaurantHandler.Approve)
				restaurantsAuth.POST("/:id/reject", middleware.RequireRole("admin"), restaurantHandler.Reject)
			}
		}

		offersGroup := v1.Group("/offers")
		{
			offersGroup.GET("", offerHandler.List)
			offersGroup.GET("/:id", offerHandler.Get)
			offersAuth := offersGroup.Group("")
			offersAuth.Use(middleware.Auth(cfg.JWT.Secret))
			offersAuth.Use(middleware.AuditTrail(auditService))
			{
				offersAuth.POST("", offerHandler.Create)
				offersAuth.PUT("/:id", offerHandler.Update)
				offersAuth.DELETE("/:id", offerHandler.Delete)
				offersAuth.POST("/:id/approve", middleware.RequireRole("admin"), offerHandler.Approve)
				offersAuth.POST("/:id/reject", middleware.RequireRole("admin"), offerHandler.Reject)
				offersAuth.POST("/:id/expire", middleware.RequireRole("admin"), offerHandler.Expire)
			}
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
			uploadGroup.Use(middleware.AuditTrail(auditService))
			uploadGroup.Use(middleware.RateLimit(rdb, 10, 1*time.Minute, "rl:upload"))
			{
				uploadGroup.POST("", uploadHandler.Upload)
				uploadGroup.POST("/multiple", uploadHandler.UploadMultiple)
			}

			v1.GET("/uploads/*key", uploadHandler.ServeFile)
		}

		notificationsGroup := v1.Group("/notifications")
		notificationsGroup.Use(middleware.Auth(cfg.JWT.Secret))
		notificationsGroup.Use(middleware.AuditTrail(auditService))
		{
			notificationsGroup.GET("", notificationHandler.List)
			notificationsGroup.GET("/unread-count", notificationHandler.UnreadCount)
			notificationsGroup.PUT("/:id/read", notificationHandler.MarkAsRead)
			notificationsGroup.PUT("/read-all", notificationHandler.MarkAllAsRead)
		}

		devicesGroup := v1.Group("/devices")
		devicesGroup.Use(middleware.Auth(cfg.JWT.Secret))
		devicesGroup.Use(middleware.AuditTrail(auditService))
		{
			devicesGroup.POST("", notificationHandler.RegisterDevice)
			devicesGroup.DELETE("", notificationHandler.UnregisterDevice)
		}

		dashboardGroup := v1.Group("/dashboard")
		dashboardGroup.Use(middleware.Auth(cfg.JWT.Secret))
		dashboardGroup.Use(middleware.RequireDashboardAccess())
		dashboardGroup.Use(middleware.RequireActive(userRepo))
		dashboardGroup.Use(middleware.OwnerScoped())
		dashboardGroup.Use(middleware.AuditTrail(auditService))
		{
			dashboardGroup.GET("/stats", dashboardHandler.Stats)
			dashboardGroup.GET("/restaurants", dashboardHandler.ListRestaurants)
			dashboardGroup.GET("/restaurants/:id", dashboardHandler.GetRestaurant)
			dashboardGroup.POST("/restaurants", dashboardHandler.CreateRestaurant)
			dashboardGroup.PUT("/restaurants/:id", dashboardHandler.UpdateRestaurant)
			dashboardGroup.DELETE("/restaurants/:id", dashboardHandler.DeleteRestaurant)
			dashboardGroup.GET("/offers", dashboardHandler.ListOffers)
			dashboardGroup.GET("/offers/:id", dashboardHandler.GetOffer)
			dashboardGroup.POST("/offers", dashboardHandler.CreateOffer)
			dashboardGroup.PUT("/offers/:id", dashboardHandler.UpdateOffer)
			dashboardGroup.DELETE("/offers/:id", dashboardHandler.DeleteOffer)
		}

		adminGroup := v1.Group("/admin")
		adminGroup.Use(middleware.Auth(cfg.JWT.Secret))
		adminGroup.Use(middleware.RequireActive(userRepo))
		adminGroup.Use(middleware.RequireRole("admin"))
		adminGroup.Use(middleware.AuditTrail(auditService))
		{
			adminGroup.POST("/impersonate", impersonationHandler.Start)
			adminGroup.GET("/stats", adminHandler.Stats)
			adminGroup.GET("/stats/timeline", adminHandler.StatsTimeline)
			adminGroup.GET("/notifications", adminHandler.ListNotifications)
			adminGroup.POST("/notifications/push", notificationHandler.SendPush)
			adminGroup.GET("/audit-log", auditLogHandler.List)
			adminGroup.POST("/restaurants/bulk", adminHandler.BulkRestaurants)
			adminGroup.POST("/offers/bulk", adminHandler.BulkOffers)
			adminGroup.GET("/owners", adminHandler.ListOwners)
			adminGroup.POST("/users/bulk", adminHandler.BulkUsers)
			adminGroup.GET("/analytics/top-restaurants", adminHandler.AnalyticsTopRestaurants)
			adminGroup.GET("/analytics/top-offers", adminHandler.AnalyticsTopOffers)
			adminGroup.GET("/analytics/user-growth", adminHandler.AnalyticsUserGrowth)
			adminGroup.GET("/analytics/offer-stats", adminHandler.AnalyticsOfferStats)
			adminGroup.GET("/notification-templates", templateHandler.List)
			adminGroup.POST("/notification-templates", templateHandler.Create)
			adminGroup.PUT("/notification-templates/:id", templateHandler.Update)
			adminGroup.DELETE("/notification-templates/:id", templateHandler.Delete)
			adminGroup.GET("/notification-analytics", func(c *gin.Context) {
				stats, err := scheduledNotificationRepo.Stats()
				if err != nil {
					response.InternalError(c, "failed to get analytics")
					return
				}
				response.Success(c, stats)
			})
			adminGroup.GET("/coupons", couponHandler.List)
			adminGroup.POST("/coupons", couponHandler.Create)
			adminGroup.PUT("/coupons/:id", couponHandler.Update)
			adminGroup.DELETE("/coupons/:id", couponHandler.Delete)
			adminGroup.POST("/coupons/:id/activate", couponHandler.Activate)
			adminGroup.POST("/coupons/:id/deactivate", couponHandler.Deactivate)
			adminGroup.GET("/categories", categoryHandler.List)
			adminGroup.POST("/categories", categoryHandler.Create)
			adminGroup.PUT("/categories/:id", categoryHandler.Update)
			adminGroup.DELETE("/categories/:id", categoryHandler.Delete)
		}

		impersonationGroup := v1.Group("/admin")
		impersonationGroup.Use(middleware.Auth(cfg.JWT.Secret))
		impersonationGroup.Use(middleware.RequireActive(userRepo))
		impersonationGroup.Use(middleware.AuditTrail(auditService))
		{
			impersonationGroup.POST("/impersonate/stop", impersonationHandler.Stop)
			impersonationGroup.GET("/impersonate/status", impersonationHandler.Status)
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
