package main

import (
	"fmt"
	"path/filepath"
)

func checkModuleFileNames() (moduleFileToId map[string]string, err error) {
	fmt.Println("\n=== START finding module files that doesn't match module name ===")
	moduleFileToId = map[string]string{}
	err = readYamlFilesInDir(filepath.Join(pipelineModulesDir, "*", "*"), func(filePath string, fileContent Module) (breakFu bool, err error) {
		fileName := filepath.Base(filePath)
		fileExt := filepath.Ext(fileName)
		fileNameWithoutExt := fileName[:len(fileName)-len(fileExt)]

		moduleId := toType(fileContent["name"], "")
		if fileNameWithoutExt != moduleId {
			moduleFileToId[filePath] = moduleId
			fmt.Printf("%20s != %-20s | %s\n", fileNameWithoutExt, moduleId, filePath)

			// newPath := filepath.Join(filepath.Dir(filePath), moduleId+fileExt)
			// os.Rename(filePath, newPath)
		}
		return
	})

	fmt.Println("\n=== DONE finding module files that doesn't match module name ===")
	return
}
