package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path"
	"path/filepath"

	"github.com/stretchr/stew/slice"
	"gopkg.in/yaml.v3"
)

type Module map[string]interface{}

func main() {
	// Define the input and output directories
	services := []string{"app-service", "infra-service", "deployment-service"}
	targets := []string{"integration", "infra", "deployment"}
	pipelineModulesDir := "./pipeline-modules/"
	outputDir := "./modules"

	moduleIndexedByName := map[string]Module{}
	allInputs := map[string]interface{}{} // target:input

	for i, t := range targets {
		inputDir := filepath.Join(pipelineModulesDir, services[i])
		scanDir(inputDir, t, moduleIndexedByName, allInputs)
	}

	os.RemoveAll(outputDir)
	for _, m := range moduleIndexedByName {
		writeModule(outputDir, m)
	}

	if len(moduleIndexedByName) == 0 || len(allInputs) == 0 {
		return
	}

	inputs := map[string]interface{}{
		"properties": allInputs,
	}
	newData, err := yaml.Marshal(inputs)
	if err != nil {
		log.Fatal(err)
	}

	inputFile := filepath.Join(outputDir, "internal-inputs.yaml")
	err = ioutil.WriteFile(inputFile, newData, 0644)
	if err != nil {
		log.Fatal(err)
	}
}

func scanDir(inputDir, target string, moduleIndexedByName map[string]Module, allInputs map[string]interface{}) {
	// Find all YAML files in the input directory
	pattern := path.Join(inputDir, "**", "*.yaml")
	log.Default().Println("search pattern: " + pattern)
	files, err := filepath.Glob(pattern)
	if err != nil {
		log.Fatal(err)
	}

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

		module.ExtractInternalInputs(allInputs)
		cloud := module.ExtractCloud()
		t := module.ExtractTemplate()
		name := module.GetName()
		delete(module, "target")

		existingModule, alreadyExists := moduleIndexedByName[name]
		if alreadyExists {
			templates := toType(existingModule["templates"], map[string]string{})
			templates[cloud] = t
			targets := toType(existingModule["targets"], []string{})
			if !slice.ContainsString(targets, target) {
				existingModule["targets"] = append(targets, target)
			}
		} else {
			module["templates"] = map[string]string{cloud: t}
			module["targets"] = []string{target}
			moduleIndexedByName[name] = module
		}
	}
}

func writeModule(outputDir string, module Module) {
	name := module.GetName()
	templates := toType(module["templates"], map[string]string{})
	delete(module, "templates")

	// Encode the Config struct back into YAML
	newData, err := yaml.Marshal(module)
	if err != nil {
		log.Fatal(err)
	}

	moduleDir := filepath.Join(outputDir, name)
	templateDir := filepath.Join(moduleDir, "templates")
	// Create the output directory if it doesn't exist
	err = os.MkdirAll(templateDir, 0755)
	if err != nil {
		log.Fatal(err)
	}

	// Write the modified YAML data to a new file in the output directory
	metaFile := filepath.Join(moduleDir, "metadata.yaml")
	err = ioutil.WriteFile(metaFile, newData, 0644)
	if err != nil {
		log.Fatal(err)
	}

	for cloud, template := range templates {
		// Write the modified YAML data to a new file in the output directory
		templateFile := filepath.Join(templateDir, fmt.Sprintf("%s.yaml", cloud))
		err = ioutil.WriteFile(templateFile, []byte(template), 0644)
		if err != nil {
			log.Fatal(err)
		}
	}
}

func (m Module) GetName() string {
	return toType(m["name"], "")
}
func (m *Module) ExtractCloud() string {
	provisioner := toType((*m)["provisioner"], "")
	delete(*m, "provisioner")
	return provisioner
}

func (m *Module) ExtractTemplate() string {
	t := toType((*m)["template"], "")
	delete(*m, "template")
	return t
}

func (m *Module) ExtractInternalInputs(allInputs map[string]interface{}) {
	inputs := toType((*m)["inputs"], Module{})
	inputProperties := toType(inputs["properties"], Module{})
	inputInternals := toType(inputs["internal"], []interface{}{})

	for _, internalField := range inputInternals {
		fieldName := toType(internalField, "")
		allInputs[fieldName] = toType(inputProperties[fieldName], Module{})
		delete(inputProperties, fieldName)
	}
	inputs["properties"] = inputProperties

	(*m)["inputs"] = inputs
}

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
