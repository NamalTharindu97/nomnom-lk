package handlers

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/response"
)

type CouponHandler struct {
	repo *repository.CouponRepo
}

func NewCouponHandler(repo *repository.CouponRepo) *CouponHandler {
	return &CouponHandler{repo: repo}
}

type couponRequest struct {
	Code           string  `json:"code" binding:"required,max=50"`
	DiscountType   string  `json:"discount_type"`
	DiscountValue  float64 `json:"discount_value" binding:"required"`
	MinOrderAmount float64 `json:"min_order_amount"`
	MaxUses        int     `json:"max_uses"`
	StartsAt       string  `json:"starts_at"`
	ExpiresAt      string  `json:"expires_at"`
}

func (h *CouponHandler) List(c *gin.Context) {
	page, perPage := 1, 20
	coupons, total, err := h.repo.FindAll(page, perPage)
	if err != nil {
		response.InternalError(c, "failed to list coupons")
		return
	}
	if coupons == nil {
		coupons = []models.Coupon{}
	}
	response.Success(c, gin.H{"data": coupons, "total": total})
}

func (h *CouponHandler) Create(c *gin.Context) {
	var req couponRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "body", Message: err.Error()}})
		return
	}

	dt := "percentage"
	if req.DiscountType != "" {
		dt = req.DiscountType
	}

	coupon := &models.Coupon{
		Code:           req.Code,
		DiscountType:   dt,
		DiscountValue:  req.DiscountValue,
		MinOrderAmount: req.MinOrderAmount,
		MaxUses:        req.MaxUses,
	}

	if req.StartsAt != "" {
		t, err := time.Parse(time.RFC3339, req.StartsAt)
		if err == nil {
			coupon.StartsAt = &t
		}
	}
	if req.ExpiresAt != "" {
		t, err := time.Parse(time.RFC3339, req.ExpiresAt)
		if err == nil {
			coupon.ExpiresAt = &t
		}
	}

	if err := h.repo.Create(coupon); err != nil {
		response.InternalError(c, "failed to create coupon")
		return
	}
	response.SuccessCreated(c, coupon)
}

func (h *CouponHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid coupon id"}})
		return
	}

	var req couponRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "body", Message: err.Error()}})
		return
	}

	coupon, err := h.repo.FindByID(id)
	if err != nil {
		response.NotFound(c, "coupon not found")
		return
	}

	coupon.Code = req.Code
	coupon.DiscountType = req.DiscountType
	if coupon.DiscountType == "" {
		coupon.DiscountType = "percentage"
	}
	coupon.DiscountValue = req.DiscountValue
	coupon.MinOrderAmount = req.MinOrderAmount
	coupon.MaxUses = req.MaxUses

	if req.StartsAt != "" {
		t, _ := time.Parse(time.RFC3339, req.StartsAt)
		coupon.StartsAt = &t
	}
	if req.ExpiresAt != "" {
		t, _ := time.Parse(time.RFC3339, req.ExpiresAt)
		coupon.ExpiresAt = &t
	}

	if err := h.repo.Update(coupon); err != nil {
		response.InternalError(c, "failed to update coupon")
		return
	}
	response.Success(c, coupon)
}

func (h *CouponHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid coupon id"}})
		return
	}
	if err := h.repo.Delete(id); err != nil {
		response.InternalError(c, "failed to delete coupon")
		return
	}
	response.SuccessNoContent(c)
}

func (h *CouponHandler) Activate(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid coupon id"}})
		return
	}
	if err := h.repo.Activate(id); err != nil {
		response.InternalError(c, "failed to activate coupon")
		return
	}
	response.Success(c, gin.H{"message": "coupon activated"})
}

func (h *CouponHandler) Deactivate(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid coupon id"}})
		return
	}
	if err := h.repo.Deactivate(id); err != nil {
		response.InternalError(c, "failed to deactivate coupon")
		return
	}
	response.Success(c, gin.H{"message": "coupon deactivated"})
}
