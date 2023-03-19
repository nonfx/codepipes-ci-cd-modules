package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

type readYamlFilesInDirCB func(filePath string, fileContent Module) (breakFu bool, err error)

func readYamlFilesInDir(dir string, fu readYamlFilesInDirCB) error {
	// Find all YAML files in the input directory
	pattern := filepath.Join(dir, "*.yaml")
	files, err := filepath.Glob(pattern)
	if err != nil {
		log.Fatal(fmt.Errorf("pattern '%s' search error: %s", pattern, err))
	}
	log.Default().Printf("found %d files matching pattern: %s", len(files), pattern)

	for _, file := range files {
		// log.Default().Println(file)
		// Read the YAML file
		data, err := ioutil.ReadFile(file)
		if err != nil {
			log.Fatal(err)
		}

		// Parse the YAML data into a Config struct
		module := Module{}
		err = yaml.Unmarshal(data, &module)
		if err != nil {
			log.Fatal(err)
		}

		breakFu, err := fu(file, module)
		if err != nil {
			return err
		} else if breakFu {
			break
		}
	}

	return nil
}
