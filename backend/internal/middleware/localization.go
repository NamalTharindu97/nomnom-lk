package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"
)

const (
	LangEnglish = "en"
	LangSinhala = "si"
	LangTamil   = "ta"
)

var supportedLanguages = map[string]bool{
	LangEnglish: true,
	LangSinhala: true,
	LangTamil:   true,
}

func Localization() gin.HandlerFunc {
	return func(c *gin.Context) {
		lang := c.GetHeader("Accept-Language")
		if lang == "" {
			lang = c.DefaultQuery("lang", LangEnglish)
		}
		if !supportedLanguages[lang] {
			lang = LangEnglish
		}
		c.Set("lang", lang)
		c.Next()
	}
}

func GetLanguage(c *gin.Context) string {
	lang, exists := c.Get("lang")
	if !exists {
		return LangEnglish
	}
	return lang.(string)
}

func MergeTranslations(translations map[string]map[string]string, lang string) map[string]interface{} {
	result := make(map[string]interface{})
	for field, translations := range translations {
		if val, ok := translations[lang]; ok && val != "" {
			fieldKey := field + "_" + strings.ReplaceAll(lang, "-", "_")
			result[fieldKey] = val
		}
	}
	return result
}
