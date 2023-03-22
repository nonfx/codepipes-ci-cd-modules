package main

import (
	"sort"
)

type Module map[string]interface{}
type ModuleInputs map[string]interface{}

func (m Module) GetName() string {
	return toType(m["name"], "")
}

func (m Module) ExtractCloud() string {
	provisioner := toType((m)["provisioner"], "")
	return provisioner
}

func (m Module) ExtractTemplate() string {
	t := toType((m)["template"], "")
	return t
}

func (m Module) ExtractInputs() (inputs ModuleInputs) {
	inputs = ModuleInputs(toType(m["inputs"], Module{}))
	return
}

// GetProperties
func (allInputs ModuleInputs) GetProperties() ModuleInputs {
	return ModuleInputs(toType(allInputs["properties"], ModuleInputs{}))
}

func (allInputs ModuleInputs) SplitUserInternal() (userInputs, internalInputs ModuleInputs) {
	allInputFields := ModuleInputs(toType(allInputs["properties"], Module{}))
	internalInputs = ModuleInputs{}
	userInputs = ModuleInputs{}

	internalInputNames := toTypeArr(toType(allInputs["internal"], []interface{}{}), "")
	sort.Strings(internalInputNames)

	for inpKey, inpDef := range allInputFields {
		if sort.SearchStrings(internalInputNames, inpKey) < len(internalInputNames) {
			// is internal
			internalInputs[inpKey] = inpDef
		} else {
			userInputs[inpKey] = inpDef
		}
	}

	return
}
