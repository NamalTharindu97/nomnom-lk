package services

import (
	"crypto/rand"
	"fmt"
	"math/big"
	"net/smtp"
	"strings"

	"github.com/nomnom-lk/backend/internal/config"
	"github.com/rs/zerolog"
)

type EmailService struct {
	cfg    *config.SMTPConfig
	log    zerolog.Logger
	client *smtp.Client
}

func NewEmailService(cfg *config.SMTPConfig, log zerolog.Logger) *EmailService {
	return &EmailService{cfg: cfg, log: log}
}

func (s *EmailService) IsEnabled() bool {
	return s.cfg.Host != "" && s.cfg.Username != "" && s.cfg.Password != ""
}

func (s *EmailService) SendVerificationCode(to, code string) error {
	if !s.IsEnabled() {
		s.log.Warn().Str("to", to).Msg("SMTP not configured, skipping verification email")
		return nil
	}

	subject := "Verify your NomNom LK account"
	body := fmt.Sprintf(`Hi there,

Your NomNom LK verification code is: %s

Enter this code in the app to activate your account. This code expires in 10 minutes.

If you didn't create this account, you can ignore this email.

Thanks,
NomNom LK`, code)

	return s.send(to, subject, body)
}

func (s *EmailService) send(to, subject, body string) error {
	auth := smtp.PlainAuth("", s.cfg.Username, s.cfg.Password, s.cfg.Host)

	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%s",
		s.cfg.From, to, subject, body)

	addr := fmt.Sprintf("%s:%d", s.cfg.Host, s.cfg.Port)

	if err := smtp.SendMail(addr, auth, s.cfg.Username, []string{to}, []byte(msg)); err != nil {
		s.log.Error().Err(err).Str("to", to).Msg("failed to send email")
		return fmt.Errorf("failed to send email: %w", err)
	}

	s.log.Info().Str("to", to).Msg("verification email sent")
	return nil
}

func (s *EmailService) GenerateCode() (string, error) {
	const digits = "0123456789"
	code := make([]byte, 6)
	for i := range code {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(digits))))
		if err != nil {
			return "", fmt.Errorf("failed to generate code: %w", err)
		}
		code[i] = digits[n.Int64()]
	}
	return string(code), nil
}

func FormatEmailAddress(name, email string) string {
	if strings.ContainsAny(name, "<>") {
		return email
	}
	return fmt.Sprintf("%s <%s>", name, email)
}
