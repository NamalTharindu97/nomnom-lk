package request

type SearchQuery struct {
	Query    string  `form:"q"`
	Type     string  `form:"type" default:"all"`
	Lat      float64 `form:"lat"`
	Lng      float64 `form:"lng"`
	RadiusKm float64 `form:"radius_km" default:"10"`
	Page     int     `form:"page" default:"1"`
	PerPage  int     `form:"per_page" default:"20"`
}
