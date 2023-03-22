package main

import (
	"fmt"
	"path/filepath"

	"github.com/stretchr/testify/assert"
)

type moduleInputsIndex map[string]map[string]map[string]ModuleInputs // moduleName: service: cloud: inputs

func moduleInputsDiff() (err error) {
	fmt.Println("\n=== START finding diff for reach module across cloud and target ===")
	inputsIndex := moduleInputsIndex{}

	err = readYamlFilesInDir(filepath.Join(pipelineModulesDir, "*", "*"), func(filePath string, fileContent Module) (breakFu bool, err error) {
		dir := filepath.Dir(filePath)
		_, cloudName := filepath.Split(dir)
		_, serviceName := filepath.Split(filepath.Dir(dir))

		inputsIndex.Set(fileContent.GetName(), serviceName, cloudName, fileContent.ExtractInputs())
		return // true, nil
	})

	assert := assert.New(logger{})
	// modules loop
	// for _, moduleName := range []string{"sonar-cloud"} {
	for moduleName := range inputsIndex {
		var compareAgainstInp ModuleInputs
		var compareAgainstMsg string

		// services
		for serviceName := range inputsIndex[moduleName] {

			if len(inputsIndex[moduleName]) < 2 && len(inputsIndex[moduleName][serviceName]) < 2 {
				continue
			}

			// cloud
			for cloudName, inputs := range inputsIndex[moduleName][serviceName] {

				path := fmt.Sprintf("%s.%s", serviceName, cloudName)
				if compareAgainstInp == nil {
					fmt.Printf("\n- Module: %s \n", moduleName)

					compareAgainstInp = inputs
					compareAgainstMsg = path
					continue
				}

				assert.Equal(compareAgainstInp, inputs, "-%s != +%s", compareAgainstMsg, path)
			}
		}

	}
	fmt.Println("\n=== DONE finding diff for reach module across cloud and target ===")
	return
}

func (ind moduleInputsIndex) Set(moduleName, serviceName, cloudName string, allInputs ModuleInputs) {
	if _, exists := ind[moduleName]; !exists {
		ind[moduleName] = map[string]map[string]ModuleInputs{}
	}

	if _, exists := ind[moduleName][serviceName]; !exists {
		ind[moduleName][serviceName] = map[string]ModuleInputs{}
	}

	if _, exists := ind[moduleName][serviceName][cloudName]; !exists {
		ind[moduleName][serviceName][cloudName] = ModuleInputs{}
	}

	ind[moduleName][serviceName][cloudName] = allInputs
}
