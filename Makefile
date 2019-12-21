# Git
export GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
export GIT_COMMIT ?= $(shell git rev-parse HEAD)
export GIT_OPTIONS ?=
export GIT_REMOTES ?= $(shell git remote -v | awk '{ print $1; }' | sort | uniq)
export GIT_TAG ?= $(shell git tag -l --points-at HEAD | head -1)

# Paths
# resolve the makefile's path and directory, from https://stackoverflow.com/a/18137056
export MAKE_PATH		?= $(abspath $(lastword $(MAKEFILE_LIST)))
export ROOT_PATH		?= $(dir $(MAKE_PATH))

NODE_BIN := $(ROOT_PATH)/node_modules/.bin
SCRIPT_PATH := $(ROOT_PATH)/scripts

# CI
export CI_COMMIT_REF_SLUG ?= $(GIT_BRANCH)
export CI_COMMIT_SHA ?= $(GIT_COMMIT)
export CI_COMMIT_TAG ?= $(GIT_TAG)
export CI_ENVIRONMENT_SLUG ?= local
export CI_JOB_ID ?= 0
export CI_PROJECT_PATH ?= $(shell ROOT_PATH=$(ROOT_PATH) ${SCRIPT_PATH}/ci-project-path.sh)
export CI_RUNNER_DESCRIPTION ?= $(shell hostname)
export CI_RUNNER_ID ?= $(shell hostname)
export CI_RUNNER_VERSION ?= 0.0.0

# Package
export PACKAGE_NAME := $(shell cat $(ROOT_PATH)/package.json | jq .name)
export PACKAGE_VERSION := $(shell cat $(ROOT_PATH)/package.json | jq .version)

# Image
IMAGE_ARGS ?=

.PHONY: help build-image git-push node_modules release-dry release-run

default: help
build: build-image

# from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## print this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort \
		| sed 's/^.*\/\(.*\)/\1/' \
		| awk 'BEGIN {FS = ":[^:]*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

node_modules: ## install javascript packages (for changelog & release)
	yarn

build-image:
	VERSION_FLAGS="\
		-X main.CIBuildJob='$(CI_JOB_ID)' \
		-X main.CIBuildNode='$(CI_RUNNER_DESCRIPTION)' \
		-X main.CIBuildRunner='$(CI_RUNNER_ID)' \
		-X main.CIGitBranch='$(CI_COMMIT_REF_SLUG)' \
		-X main.CIGitCommit='$(CI_COMMIT_SHA)' \
		-X main.CIPackageName='$(PACKAGE_NAME)' \
		-X main.CIPackageVersion='$(PACKAGE_VERSION)'" \
	IMAGE_ARGS='--build-arg VERSION_FLAGS' \
		./scripts/docker-build.sh $(IMAGE_ARGS)

test-schema-all:
	pg_prove $(shell find test/ -name '*.sql' | paste -sd " ")

test-schema-compat: ## skip any test suite with tables in the name for compat views
	pg_prove $(shell find test/ -name '*.sql' | grep -v tables | paste -sd " ")

git-push: ## push to both gitlab and github (this assumes you have both remotes set up)
	git push $(GIT_OPTIONS) github $(GIT_BRANCH)
	git push $(GIT_OPTIONS) gitlab $(GIT_BRANCH)

release-dry: ## test creating a release
	$(NODE_BIN)/standard-version --sign $(RELEASE_OPTS) --dry-run

release-run: ## create a release
	$(NODE_BIN)/standard-version --sign $(RELEASE_OPTS)
	GIT_OPTIONS=--tags $(MAKE) git-push

upload-codecov:
	codecov --disable=gcov \
		--file=out/cover.out \
		--token=$(shell echo "${CODECOV_SECRET}" | base64 -d)
