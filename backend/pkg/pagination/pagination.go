package pagination

import (
	"math"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/nomnom-lk/backend/pkg/response"
)

const (
	DefaultPage    = 1
	DefaultPerPage = 20
	MaxPerPage     = 100
)

type Params struct {
	Page    int
	PerPage int
	Offset  int
}

func Extract(c *gin.Context) Params {
	page := DefaultPage
	perPage := DefaultPerPage

	if p, err := strconv.Atoi(c.DefaultQuery("page", "1")); err == nil && p > 0 {
		page = p
	}
	if pp, err := strconv.Atoi(c.DefaultQuery("per_page", "20")); err == nil && pp > 0 {
		perPage = pp
		if perPage > MaxPerPage {
			perPage = MaxPerPage
		}
	}

	offset := (page - 1) * perPage
	return Params{
		Page:    page,
		PerPage: perPage,
		Offset:  offset,
	}
}

func Meta(p Params, total int64) response.PaginationMeta {
	totalPages := 0
	if p.PerPage > 0 {
		totalPages = int(math.Ceil(float64(total) / float64(p.PerPage)))
	}
	return response.PaginationMeta{
		Page:       p.Page,
		PerPage:    p.PerPage,
		Total:      total,
		TotalPages: totalPages,
	}
}
