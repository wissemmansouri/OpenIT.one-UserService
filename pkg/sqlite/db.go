package sqlite

import (
	"time"

	"github.com/glebarez/sqlite"
	"github.com/wissemmansouri/OpenIT.one-Common/utils/logger"
	"github.com/wissemmansouri/OpenIT.one-UserService/model"
	"github.com/wissemmansouri/OpenIT.one-UserService/pkg/utils/file"
	model2 "github.com/wissemmansouri/OpenIT.one-UserService/service/model"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

var gdb *gorm.DB

func GetDb(dbPath string) *gorm.DB {
	if gdb != nil {
		return gdb
	}

	file.IsNotExistMkDir(dbPath)
	db, err := gorm.Open(sqlite.Open(dbPath+"/user.db"), &gorm.Config{})
	if err != nil {
		panic(err)
	}

	c, _ := db.DB()
	c.SetMaxIdleConns(10)
	c.SetMaxOpenConns(1)
	c.SetConnMaxIdleTime(time.Second * 1000)

	gdb = db

	err = db.AutoMigrate(model2.UserDBModel{}, model.EventModel{})
	if err != nil {
		logger.Error("check or create db error", zap.Any("error", err))
	}
	return db
}
