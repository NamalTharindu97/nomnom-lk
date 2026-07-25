package request

type SearchQuery struct {
	Query   string `form:"q"`
	Type    string `form:"type" default:"all"`
	Page    int    `form:"page" default:"1"`
	PerPage int    `form:"per_page" default:"20"`
}
