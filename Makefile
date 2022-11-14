SHELL:=/bin/bash

ifeq (${TEST_VERSION},)
	## This means master of our suite
	export TEST_VERSION = d007a0d506a52535c8cd20c0905fa1700f26bcdf
endif

ifeq (${TEST_ENV},)
	TEST_ENV=Docker
endif

ifeq (${TEST_REGEX},)
	TEST_REGEX = Test
endif

ifeq (${TEST_TAG},)
	TEST_TAG = publicbundle
endif

ifeq (${TEST_REPORT_NAME},)
	TEST_REPORT_NAME = Codepipes Public Bundle Tests
endif

ifeq (${TEST_AZURE_BUILD_BRANCH},)
	TEST_AZURE_BUILD_BRANCH = master
endif

ifeq (${TEST_AZURE_BUILD_URL},)
	TEST_AZURE_BUILD_URL = https://dev.azure.com/
endif

ifeq (${TEST_CLEANUP_ALL},)
	TEST_CLEANUP_ALL = false
endif

test-public-bundle:
	mkdir -p report || true; set -o pipefail; . ./.env.tests && go test ./publicbundle -v -defaultOrg -testSuiteName="API Result Public Bundles(codepipes-ci-cd)" -testify.m="${TEST_REGEX}" --tags="publicbundle" -env="${TEST_ENV}" -user="${TEST_USER}" -password="${TEST_PASSWORD}" -gitRef="${TEST_AZURE_BUILD_BRANCH}" -azureBuildUrl="${TEST_AZURE_BUILD_URL}" -timeout 600000s -credindex=0 | tee -a ${PWD}/report/APIResultPublicBundle.log