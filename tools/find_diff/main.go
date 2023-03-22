package main

// Define the input and output directories
var services = []string{"app-service", "infra-service", "deployment-service"}
var clouds = []string{"aws", "gcp", "azure"}
var targets = []string{"integration", "infra", "deployment"}
var pipelineModulesDir = "./pipeline-modules/"
var outputDir = "./modules"

func main() {
	checkModuleFileNames()
	moduleInputsDiff()
}
