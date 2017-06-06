######################################################################
# Thanks:
#   https://github.com/aktau/github-release
#   https://github.com/c4milo/github-release
#   https://github.com/MozillaSecurity/dolly
#   https://gist.github.com/danielestevez/2044589
#   https://github.com/vaab/gitchangelog
######################################################################


######################################################################
# Constants
######################################################################

# Customize your project settings in this file.  
include conf/make-project-settings.mk

LAST_TAG := $(shell git describe --abbrev=0 --tags)
COMPARISON="$(LAST_TAG)..HEAD"

RELEASE_SUPPORT := scripts/make-release-support.sh
VERSION=$(shell . $(RELEASE_SUPPORT) ; getVersion)
TAG=$(shell . $(RELEASE_SUPPORT); getTag)

.PHONY: clean-pyc clean-build docs clean

help:
	@echo "check-status  - will check whether there are outstanding changes."
	@echo "check-release - will check whether the current directory matches the tagged release in git."
	@echo "patch-release - increments the patch release level, build and push to github."
	@echo "minor-release - increments the minor release level, build and push to github."
	@echo "major-release - increments the major release level, build and push to github."
	@echo "clean         - remove all build artifacts"
	@echo "clean-build   - remove build artifacts"
	@echo "clean-pyc     - remove Python file artifacts"
	@echo "showver       - will show the current release tag based on the directory content."
	@echo "dist          - package"

tag-patch-release: VERSION := $(shell . $(RELEASE_SUPPORT); nextPatchLevel)
tag-patch-release: .release tag

tag-minor-release: VERSION := $(shell . $(RELEASE_SUPPORT); nextMinorLevel)
tag-minor-release: .release tag

tag-major-release: VERSION := $(shell . $(RELEASE_SUPPORT); nextMajorLevel)
tag-major-release: .release tag 

tag: TAG=$(shell . $(RELEASE_SUPPORT); getTag $(VERSION))
tag: check-status
	@. $(RELEASE_SUPPORT) ; ! tagExists $(TAG) || (echo "ERROR: tag $(TAG) for version $(VERSION) already tagged in git" >&2 && exit 1) ;
	@. $(RELEASE_SUPPORT) ; setRelease $(VERSION)
	@git add .release
	@git commit -am "Version bumped to $(VERSION)"
	@git tag -a "$(VERSION)" -m "release $(VERSION)"
	@gitchangelog > ./CHANGELOG.md
	@git tag -d "$(VERSION)"
	@git add CHANGELOG.md
	rm -f change.log
	bin/changelog init
	bin/changelog prepare
	bin/changelog finalize --version="$(VERSION)"
	bin/changelog md --out=CHANGELOG2.md
	@git commit -am "New: CHANGELOG2.md generated"
	git tag -a "$(VERSION)" -m "release $(VERSION)"
	@git push
	@git push --tags
	@changelog=$$(git log $(COMPARISON) --oneline --no-merges) ; \
	echo "**Changelog $(VERSION)**<br/>$$changelog"; \
	bin/github-release release -u abnerjacobsen -r rootfs-alpine-3.6 -t $(VERSION) -n $(VERSION) -d "**Changelog**<br/>$$changelog"

patch-release: tag-patch-release release
	@echo $(VERSION)

minor-release: tag-minor-release release
	@echo $(VERSION)

major-release: tag-major-release release
	@echo $(VERSION)

.release:
	@echo "release=0.0.0" > .release
	@echo "tag=$(GITHUB_PROJECT)-0.0.0" >> .release
	@echo INFO: .release created
	@cat .release

#release: check-status check-release
release: check-status

showver: .release
	@. $(RELEASE_SUPPORT); getVersion

check-status:
	@. $(RELEASE_SUPPORT) ; ! hasChanges || (echo "ERROR: there are still outstanding changes" >&2 && exit 1) ;

check-release: .release
	@. $(RELEASE_SUPPORT) ; tagExists $(TAG) || (echo "ERROR: version not yet tagged in git. make [minor,major,patch]-release." >&2 && exit 1) ;
	@. $(RELEASE_SUPPORT) ; ! differsFromRelease $(TAG) || (echo "ERROR: current directory differs from tagged $(TAG). make [minor,major,patch]-release." ; exit 1)

clean: clean-build clean-pyc clean-test
	find . -name '*~' -exec rm -f {} +

clean-build:
	rm -rf build/
	rm -rf dist/
	rm -rf .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +
	find . -name '*~' -exec rm -f {} +

clean-test:
	rm -rf .tox/
	rm -f .coverage
	rm -rf htmlcov/

dist: clean
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist


