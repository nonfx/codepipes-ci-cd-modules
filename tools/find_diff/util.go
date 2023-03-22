package main

import (
	"fmt"
)

func toType[T any](inp interface{}, defaultOut T) T {
	switch v := inp.(type) {
	case T:
		return v
	case *T:
		return *v
	default:
		return defaultOut
	}
}

func toTypeArr[IN_T, OUT_T any](inp []IN_T, defaultOut OUT_T) []OUT_T {
	newArr := make([]OUT_T, len(inp))
	for i, v := range inp {
		newArr[i] = toType(v, defaultOut)
	}
	return newArr
}

type logger struct{}

func (logger) Errorf(format string, args ...interface{}) {
	fmt.Printf(format, args...)
}
