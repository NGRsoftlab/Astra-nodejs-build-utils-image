SHELL                         = /bin/bash
MAKEFILE_LOCATION             = $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
ROOT_DIRECTORY                = ${CURDIR}
OS_NAME                       = $(shell uname | tr [:upper:] [:lower:])
OS_ARCH                       = $(shell uname -m)

## Define arch
ifeq ($(OS_ARCH), armv5*)
	ARCHITECTURE                := armv5
else ifeq ($(OS_ARCH), armv6*)
	ARCHITECTURE                := armv6
else ifeq ($(OS_ARCH), armv7*)
	ARCHITECTURE                := arm
else ifeq ($(OS_ARCH), aarch64)
	ARCHITECTURE                := arm64
else ifeq ($(OS_ARCH), x86)
	ARCHITECTURE                := 386
else ifeq ($(OS_ARCH), x86_64)
	ARCHITECTURE                := amd64
else ifeq ($(OS_ARCH), i686)
	ARCHITECTURE                := 386
else ifeq ($(OS_ARCH), i386)
	ARCHITECTURE                := 386
else ifeq ($(OS_ARCH), loong64)
	ARCHITECTURE                := loong64
else ifeq ($(OS_ARCH), mips)
	ARCHITECTURE                := mips
else ifeq ($(OS_ARCH), mipsle)
	ARCHITECTURE                := mipsle
else ifeq ($(OS_ARCH), mips64)
	ARCHITECTURE                := mips64
else ifeq ($(OS_ARCH), mips64le)
	ARCHITECTURE                := mips64le
else ifeq ($(OS_ARCH), ppc64)
	ARCHITECTURE                := ppc64
else ifeq ($(OS_ARCH), ppc64le)
	ARCHITECTURE                := ppc64le
else ifeq ($(OS_ARCH), riscv64)
	ARCHITECTURE                := riscv64
else ifeq ($(OS_ARCH), s390x)
	ARCHITECTURE                := s390x
else
	ARCHITECTURE                := unknown
endif

## To see all colors, run:
#+ bash -c 'for c in {0..255}; do tput setaf "${c}"; tput setaf "${c}" | cat -v; echo ="${c}"; done'
## The first 15 entries are the 8-bit colors
## For work needed set TERM to xterm: 'export TERM=xterm-256color'
## Define standard colors
ifneq (,$(findstring xterm,${TERM}))
	BLACK                       := $(shell tput -Txterm setaf 0)
	RED                         := $(shell tput -Txterm setaf 1)
	GREEN                       := $(shell tput -Txterm setaf 2)
	YELLOW                      := $(shell tput -Txterm setaf 3)
	LIGHTPURPLE                 := $(shell tput -Txterm setaf 4)
	PURPLE                      := $(shell tput -Txterm setaf 5)
	BLUE                        := $(shell tput -Txterm setaf 6)
	WHITE                       := $(shell tput -Txterm setaf 7)
	RESET                       := $(shell tput -Txterm sgr0)
else
	BLACK                       := ""
	RED                         := ""
	GREEN                       := ""
	YELLOW                      := ""
	LIGHTPURPLE                 := ""
	PURPLE                      := ""
	BLUE                        := ""
	WHITE                       := ""
	RESET                       := ""
endif

NODE_VERSION                  ?= $(if $(CI_COMMIT_REF_NAME),$(CI_COMMIT_REF_NAME),test-version)
MAKEFILE_INSTALL_DIR          ?= /usr/local
MAKEFILE_NUMBER_OF_CPUS       ?= 20 # $(shell nproc --ignore 1)
MAKEFILE_NODE_DEPLOY_DIR      ?= node-$(NODE_VERSION)-$(OS_NAME)-$(ARCHITECTURE)
MAKEFILE_SKIP_TEST            ?= FALSE
REVISION                      := $(shell git rev-parse --short=8 HEAD || echo unknown)
BRANCH                        := $(shell git show-ref | grep "$(REVISION)" | grep -v HEAD | awk '{print $$2}' | sed 's|refs/remotes/origin/||' | sed 's|refs/heads/||' | sort | head -n 1)
BUILD                         := $(shell date -u +%Y-%m-%dT%H:%M:%S%z)
LATEST_STABLE_TAG             := $(shell git -c versionsort.prereleaseSuffix="-rc" -c versionsort.prereleaseSuffix="-RC" tag -l "*.*.*" | sort -rV | awk '!/rc/' | head -n 1)
IS_LATEST                     :=
ifeq ($(shell git describe --exact-match --match $(LATEST_STABLE_TAG) >/dev/null 2>&1; echo $$?), 0)
	IS_LATEST                   := $(GREEN)true$(RESET)
else
	IS_LATEST                   := $(RED)false$(RESET)
endif

## Set target color
TARGET_COLOR                  := $(BLUE)
POUND                         = \#

## Target special targets are called phony and you can explicitly tell Make they're not associated with files
.PHONY: no_targets__ all help help-colors build version prerequisites repack application-view install test clean
	no_targets__:

.DEFAULT_GOAL := default

default:
	@echo "Usage:"
	@echo -e "\tmake\t${TARGET_COLOR}<target>${RESET}"
	@echo
	@echo "Targets:"
	@$(MAKE) -f $(MAKEFILE_LOCATION) --no-print-directory help

help-colors: ## Show all the colors
	@echo "${BLACK}BLACK${RESET}"
	@echo "${RED}RED${RESET}"
	@echo "${GREEN}GREEN${RESET}"
	@echo "${YELLOW}YELLOW${RESET}"
	@echo "${LIGHTPURPLE}LIGHTPURPLE${RESET}"
	@echo "${PURPLE}PURPLE${RESET}"
	@echo "${BLUE}BLUE${RESET}"
	@echo "${WHITE}WHITE${RESET}"

help:
	@grep --no-filename -E '^[a-zA-Z_0-9%-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN { FS = ":.*? ## " }; { printf "\t${TARGET_COLOR}%-50s${RESET} %-60s\n", $$1, $$2 }'

target-list: ## Show Makefile available target
	@bash -c "$(MAKE) -f $(MAKEFILE_LOCATION) -p no_targets__ \
		| awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' \
		| grep -v '__\$$' | grep -vE '*[1]' | grep -vE 'Makefile*' \
		| sort"

## Check if 'MAKEFILE_SKIP_TEST' is 'TRUE' then run targets without test
ifeq ($(MAKEFILE_SKIP_TEST), TRUE)
all: variables-list prerequisites version build install application-view
else
all: variables-list prerequisites version build test install application-view ## Build, test and deploy current build
endif

version: ## Show information about current version
	@echo -e "Current version:\t $(NODE_VERSION)"
	@echo -e "Current revision:\t $(REVISION)"
	@echo -e "Current branch:\t\t $(BRANCH)"
	@echo -e "Is latest tag:\t\t $(GREEN)$(IS_LATEST)$(RESET)"

# Put this at the point where you want to see the variable values
variables-list: ## Show variables defined on this Makefile build
	$(foreach v, $(.VARIABLES), $(if $(filter file,$(origin $(v))), $(info $(v)=$($(v)))))
	@echo "${GREEN}---VARIABLES PREVIEW IS OVER---${RESET}"
	@echo

# https://www.gnu.org/software/make/manual/html_node/Implicit-Variables.html
prerequisites: ## Remove previously build
	$(RM) -r ./$(MAKEFILE_NODE_DEPLOY_DIR)

build: prerequisites ## Building release build
	@echo
	@echo "${YELLOW}---CREATE CONFIGURATION---${RESET}"
	export GYP_DEFINES="benchmark=0"
	./configure
	@echo "${GREEN}---END CREATE CONFIGURATION---${RESET}"
	@echo
	@echo "${YELLOW}---BUILD PROJECT---${RESET}"
	$(MAKE) -s -j $(MAKEFILE_NUMBER_OF_CPUS) V=0
	@echo "${GREEN}---END BUILD PROJECT---${RESET}"
	@echo

test: build ## Verify the build
	@echo
	@echo "${YELLOW}---TEST PROJECT---${RESET}"
	$(MAKE) -s test-only V=0
	@echo "${GREEN}---END TESTS---${RESET}"
	@echo

install: ## Install this version of Node.js into a system directory
	@echo
	@echo "${YELLOW}---INSTALL PROJECT---${RESET}"
	$(MAKE) install PREFIX=./$(MAKEFILE_NODE_DEPLOY_DIR)
	@echo "${GREEN}---END INSTALL---${RESET}"
	@echo

application-view: ## Check build version
	./node -e "console.log('Hello from Node.js ' + process.version)"

repack: prerequisites install application-view ## Reinstall this build

clean:
	@echo
	$(RM) -r ./$(MAKEFILE_NODE_DEPLOY_DIR)
