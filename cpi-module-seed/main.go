// This script is intended to be used internally to load ci-cd modules into the DB.

package main

import (
	"context"
	_ "embed"
	"fmt"
	"os"
	"strings"

	appDB "github.com/cldcvr/vanguard-api/app-service/storage/db"
	depDB "github.com/cldcvr/vanguard-api/deployment-service/storage/db"
	infraDB "github.com/cldcvr/vanguard-api/infra-service/storage/db"
	"github.com/cldcvr/vanguard-api/pkg/configuration"
	"github.com/cldcvr/vanguard-api/pkg/db"
	"github.com/cldcvr/vanguard-api/pkg/pipeline"
	"github.com/spf13/viper"
)

const (
	infraService      = "infra-service"
	appService        = "app-service"
	deploymentService = "deployment-service"
)

var helpText string

type cmdFlag map[string]string

type dbInstanceInit interface {
	NewPostgresFromEnv(context.Context) (*db.DB, error)
}

func main() {
	configuration.LoadDefaults()

	scriptName := "cpi-module-seed"
	cmd := "help"
	cmdInput := ""
	flags := cmdFlag{}

	for i, arg := range os.Args {
		if arg == "" {
			continue
		}

		switch i {
		case 0:
			scriptName = arg
		case 1:
			cmd = arg
		case 2:
			cmdInput = arg
		default:
			splittedFlag := strings.SplitN(arg, "=", 2)
			flags[splittedFlag[0]] = ""
			if len(splittedFlag) > 1 {
				flags[splittedFlag[0]] = splittedFlag[1]
			}
		}
	}

	fmt.Printf("command: %s\n", cmd)

	switch cmd {
	case "run":
		cmdSeed()
	default: // help
		cmdHelp(scriptName, cmd, cmdInput, flags)
	}
}

func cmdHelp(scriptName string, _ string, _ string, _ cmdFlag) {
	fmt.Println(strings.ReplaceAll(helpText, "cpi-module-seed", scriptName))

	fmt.Println("The script uses following environment variables:")

	configvars := []struct {
		name      string
		sensitive bool
	}{
		{name: "pghost"},
		{name: "pgport"},
		{name: "pgsslmode"},
		{name: "pguser"},
		{name: "pgpassword", sensitive: true},
		{name: "pipeline_module_dir"},
	}

	for _, v := range configvars {
		currentvalue := "*****"
		if !v.sensitive {
			currentvalue = viper.GetString(v.name)
		}
		varName := strings.Join([]string{configuration.EnvPrefix, v.name}, "_")
		varName = strings.ToUpper(varName)
		fmt.Printf("%s=%s\n", varName, currentvalue)
	}
}

func cmdSeed() {
	baseModuleDir := configuration.RequireString("pipeline_module_dir")
	services := []string{infraService, appService, deploymentService}

	for _, service := range services {
		fmt.Printf("Migrating ci-cd modules for service=%s..... \n", service)
		seed(service, baseModuleDir)
		fmt.Printf("Successfully migrated ci-cd modules for service=%s \n", service)
	}
}

func seed(service string, baseModuleDir string) {
	var (
		err error
		da  *db.DB
	)

	success := false
	ctx := context.Background()
	moduleDirConfigKey := strings.Join([]string{configuration.EnvPrefix, "pipeline_module_dir"}, "_")
	moduleDirConfigKey = strings.ToUpper(moduleDirConfigKey)

	switch service {
	case infraService:
		modulePath := strings.Join([]string{baseModuleDir, infraService}, "/")
		os.Setenv(moduleDirConfigKey, modulePath)
		da, err = infraDB.NewPostgresFromEnv(ctx)
	case appService:
		modulePath := strings.Join([]string{baseModuleDir, appService}, "/")
		os.Setenv(moduleDirConfigKey, modulePath)
		da, err = appDB.NewPostgresFromEnv(ctx)
	case deploymentService:
		modulePath := strings.Join([]string{baseModuleDir, deploymentService}, "/")
		os.Setenv(moduleDirConfigKey, modulePath)
		da, err = depDB.NewPostgresFromEnv(ctx)
	}

	mustNotFail(err)
	txCtx := da.NewContext(ctx)
	err = da.Begin(txCtx)
	mustNotFail(err)

	defer func() {
		// rollback db transaction on failure
		if !success {
			da.Rollback(txCtx)
		}
	}()

	_ = pipeline.NewManager(ctx, da)
	success = true
}

func mustNotFail(err error) {
	if err != nil {
		panic(err)
	}
}
