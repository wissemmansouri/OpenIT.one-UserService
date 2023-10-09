package v2

import codegen "github.com/wissemmansouri/OpenIT.one-UserService/codegen/user_service"

type UserService struct{}

func NewUserService() codegen.ServerInterface {
	return &UserService{}
}
