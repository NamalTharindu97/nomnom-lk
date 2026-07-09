package locale

import (
	"encoding/json"
)

func MergeTranslations(target map[string]interface{}, translationsJSON *json.RawMessage, lang string) {
	if translationsJSON == nil || len(*translationsJSON) == 0 {
		return
	}

	var translations map[string]map[string]string
	if err := json.Unmarshal(*translationsJSON, &translations); err != nil {
		return
	}

	for field, langMap := range translations {
		if val, ok := langMap[lang]; ok && val != "" {
			target[field] = val
		}
	}
}

func BuildTranslations(nameSi, nameTa, descSi, descTa string) *json.RawMessage {
	translations := make(map[string]map[string]string)

	if nameSi != "" {
		translations["name"] = addTranslation(translations["name"], "si", nameSi)
	}
	if nameTa != "" {
		translations["name"] = addTranslation(translations["name"], "ta", nameTa)
	}
	if descSi != "" {
		translations["description"] = addTranslation(translations["description"], "si", descSi)
	}
	if descTa != "" {
		translations["description"] = addTranslation(translations["description"], "ta", descTa)
	}

	if len(translations) == 0 {
		return nil
	}

	data, _ := json.Marshal(translations)
	raw := json.RawMessage(data)
	return &raw
}

func FlattenTranslations(target map[string]interface{}, data *json.RawMessage, fieldMap map[string]string) {
	if data == nil || len(*data) == 0 {
		return
	}

	var translations map[string]map[string]string
	if err := json.Unmarshal(*data, &translations); err != nil {
		return
	}

	for field, langMap := range translations {
		mappedField, ok := fieldMap[field]
		if !ok {
			mappedField = field
		}
		for lang, val := range langMap {
			if val != "" {
				key := mappedField + "_" + lang
				target[key] = val
			}
		}
	}
}

func addTranslation(m map[string]string, lang, val string) map[string]string {
	if m == nil {
		m = make(map[string]string)
	}
	m[lang] = val
	return m
}
