package request

type RegisterDeviceRequest struct {
	Token    string `json:"token" binding:"required"`
	Platform string `json:"platform" binding:"required,oneof=ios android"`
}

type UnregisterDeviceRequest struct {
	Token string `json:"token" binding:"required"`
}

type SendPushRequest struct {
	Title      string `json:"title" binding:"required"`
	Body       string `json:"body" binding:"required"`
	Target     string `json:"target" default:"all"`
	UserID     string `json:"user_id,omitempty"`
	OfferID    string `json:"offer_id,omitempty"`
	ScheduleAt string `json:"schedule_at,omitempty"`
}
