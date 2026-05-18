# Makefile — build & push OCI packages (Helm charts and Timoni modules)
#
# Usage:
#   make push DIR=timoni/components/webservice               # push current VERSION as-is
#   make push DIR=helm/components/webservice                 # push current VERSION as-is
#   make push DIR=helm/components/webservice BUMP=patch      # patch bump + push
#   make push DIR=helm/components/webservice BUMP=minor      # minor bump + push
#   make push DIR=timoni/components/webservice VERSION=1.2.3 # set exact version + push
#   make push DIR=... DRY_RUN=1                              # print actions only
#   make bump DIR=...                                        # patch bump VERSION file only
#   make version DIR=...                                     # print current version
#
# Type is auto-detected from DIR (Chart.yaml -> Helm, cue.mod/ -> Timoni).
# The per-component VERSION file is the source of truth for versioning.
#
# All logic lives in scripts/oci-release.sh (works on macOS's GNU Make 3.81).
# Only `webservice` (helm + timoni) is functional; other folders are experiments.

REGISTRY ?= ghcr.io/coffeenights/conure-templates
# BUMP is intentionally unset by default: `make push` publishes the current
# VERSION as-is. Pass BUMP=patch|minor|major (or VERSION=x.y.z) to change it.
BUMP     ?=
VERSION  ?=
DRY_RUN  ?=

SCRIPT  := ./scripts/oci-release.sh
RUNENV   = REGISTRY='$(REGISTRY)' BUMP='$(BUMP)' VERSION='$(VERSION)' DRY_RUN='$(DRY_RUN)'
# `bump` with no BUMP given still defaults to a patch bump.
BUMPENV  = REGISTRY='$(REGISTRY)' BUMP='$(or $(BUMP),patch)' VERSION='$(VERSION)' DRY_RUN='$(DRY_RUN)'

.PHONY: help push bump version

help:
	@echo "Targets:"
	@echo "  make push DIR=<folder>     Bump version, build and push the OCI package"
	@echo "  make bump DIR=<folder>     Bump the VERSION file only (no push)"
	@echo "  make version DIR=<folder>  Print the current version"
	@echo ""
	@echo "Options: BUMP=patch|minor|major  VERSION=x.y.z  DRY_RUN=1  REGISTRY=..."
	@echo ""
	@echo "Examples:"
	@echo "  make push DIR=timoni/components/webservice"
	@echo "  make push DIR=helm/components/webservice BUMP=minor"

push:
	@$(RUNENV) $(SCRIPT) push "$(DIR)"

bump:
	@$(BUMPENV) $(SCRIPT) bump "$(DIR)"

version:
	@$(RUNENV) $(SCRIPT) version "$(DIR)"
