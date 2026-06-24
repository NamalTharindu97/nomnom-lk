package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
)

type JSONStringSlice []string

func (s *JSONStringSlice) Scan(src interface{}) error {
	if src == nil {
		*s = nil
		return nil
	}
	var source string
	switch v := src.(type) {
	case string:
		source = v
	case []byte:
		source = string(v)
	default:
		return fmt.Errorf("unsupported scan type for JSONStringSlice: %T", src)
	}
	return json.Unmarshal([]byte(source), s)
}

func (s JSONStringSlice) Value() (driver.Value, error) {
	if s == nil {
		return "[]", nil
	}
	return json.Marshal(s)
}
