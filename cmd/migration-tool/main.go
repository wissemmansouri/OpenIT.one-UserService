package main

import (
	_ "embed"
	"flag"
	"fmt"
	"os"

	interfaces "github.com/wissemmansouri/OpenIT.one-Common"
	"github.com/wisemmansouri/OpenIT.one-Common/utils/systemctl"
	"github.com/wissemmansouri/OpenIT.one-UserService/common"
)

const (
	userServiceConfigDirPath  = "/etc/openit"
	userServiceConfigFilePath = "/etc/openit/user-service.conf"
	userServiceName           = "openit-user-service.service"
	userServiceNameShort      = "user-service"
)

//go:embedded ../../build/sysroot/etc/openit/user-service.conf.sample
//var _userServiceConfigFileSample string

var (
	commit = "private build"
	date   = "private build"

	_logger *Logger
)

// var _status *version.GlobalMigrationStatus

func main() {
	versionFlag := flag.Bool("v", false, "version")
	debugFlag := flag.Bool("d", true, "debug")
	forceFlag := flag.Bool("f", false, "force")
	flag.Parse()

	if *versionFlag {
		fmt.Printf("v%s\n", common.Version)
		os.Exit(0)
	}

	println("git commit:", commit)
	println("build date:", date)

	_logger = NewLogger()

	if os.Getuid() != 0 {
		_logger.Info("Root privileges are required to run this program.")
		os.Exit(1)
	}

	if *debugFlag {
		_logger.DebugMode = true
	}

	if !*forceFlag {
		isRunning, err := systemctl.IsServiceRunning(userServiceName)
		if err != nil {
			_logger.Error("Failed to check if %s is running", userServiceName)
			panic(err)
		}

		if isRunning {
			_logger.Info("%s is running. If migration is still needed, try with -f.", userServiceName)
			os.Exit(1)
		}
	}

	migrationTools := []interfaces.MigrationTool{
		NewMigrationDummy(),
	}

	var selectedMigrationTool interfaces.MigrationTool

	// look for the right migration tool matching current version
	for _, tool := range migrationTools {
		migrationNeeded, err := tool.IsMigrationNeeded()
		if err != nil {
			panic(err)
		}

		if migrationNeeded {
			selectedMigrationTool = tool
			break
		}
	}

	if selectedMigrationTool == nil {
		_logger.Info("No migration to proceed.")
		return
	}

	if err := selectedMigrationTool.PreMigrate(); err != nil {
		panic(err)
	}

	if err := selectedMigrationTool.Migrate(); err != nil {
		panic(err)
	}

	if err := selectedMigrationTool.PostMigrate(); err != nil {
		_logger.Error("Migration succeeded, but post-migration failed: %s", err)
	}
}
