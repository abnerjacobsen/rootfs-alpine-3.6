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
	@echo "clean         - remove all build artifacts"
	@echo "clean-build   - remove build artifacts"
	@echo "clean-pyc     - remove Python file artifacts"
	@echo "showver       - will show the current release tag based on the directory content."
	@echo "test          - run tests quickly with the default Python"
	@echo "test-all      - run tests on every Python version with tox"
	@echo "coverage      - check code coverage quickly with the default Python"
	@echo "dist          - package"
	@echo "install       - install the package to the active Python's site-packages"
	@echo "release       - package and upload a release to PyPI"
	@echo "release-test  - package and upload a release to PYPI (test)"
	@echo "docs          - generate Sphinx HTML documentation, including API docs"
	@echo "lint          - check style with Pylint"

tag-patch-release: VERSION := $(shell . $(RELEASE_SUPPORT); nextPatchLevel)
tag-patch-release: .release tag

tag: TAG=$(shell . $(RELEASE_SUPPORT); getTag $(VERSION))
tag: check-status
	@. $(RELEASE_SUPPORT) ; ! tagExists $(TAG) || (echo "ERROR: tag $(TAG) for version $(VERSION) already tagged in git" >&2 && exit 1) ;
	@. $(RELEASE_SUPPORT) ; setRelease $(VERSION)
	git add .release
	git commit -am "Version bumped to $(VERSION)"
	git tag -a "$(VERSION)" -m "release $(VERSION)"
	git push
	git push --tags
	@changelog=$$(git log $(COMPARISON) --oneline --no-merges) ; \
	echo "**Changelog $(VERSION)**<br/>$$changelog"; \
	bin/github-release release -u abnerjacobsen -r rootfs-alpine-3.6 -t $(VERSION) -n $(VERSION) -d "**Changelog**<br/>$$changelog"

patch-release: tag-patch-release release3
	@echo $(VERSION)

.release:
	@echo "release=0.0.0" > .release
	@echo "tag=$(GITHUB_PROJECT)-0.0.0" >> .release
	@echo INFO: .release created
	@cat .release

#release3: check-status check-release
release3: check-status

showver: .release
	@. $(RELEASE_SUPPORT); getVersion

check-status:
	@. $(RELEASE_SUPPORT) ; ! hasChanges || (echo "ERROR: there are still outstanding changes" >&2 && exit 1) ;

check-release: .release
	@. $(RELEASE_SUPPORT) ; tagExists $(TAG) || (echo "ERROR: version not yet tagged in git. make [minor,major,patch]-release." >&2 && exit 1) ;
	@. $(RELEASE_SUPPORT) ; ! differsFromRelease $(TAG) || (echo "ERROR: current directory differs from tagged $(TAG). make [minor,major,patch]-release." ; exit 1)

# git tag -a v$(RELEASE) -m 'release $(RELEASE)'
release2:
	git push && git push --tags
	@changelog=$$(git log $(COMPARISON) --oneline --no-merges) ; \
	echo "**Changelog**<br/>$$changelog"; \
	bin/linux/amd64/github-release release -u abnerjacobsen -r rootfs-alpine-3.6 -t $(LAST_TAG) -n $(LAST_TAG) -d "**Changelog**<br/>$$changelog"

release1:
	@latest_tag=$$(git describe --tags `git rev-list --tags --max-count=1`); \
	comparison="$$latest_tag..HEAD"; \
	if [ -z "$$latest_tag" ]; then comparison=""; fi; \
	changelog=$$(git log $$comparison --oneline --no-merges); echo $$changelog;

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

test:
	python setup.py test

test-all:
	tox

coverage:
	coverage run --source {{ cookiecutter.repo_name }} setup.py test
	coverage report -m
	coverage html
	open htmlcov/index.html

release: clean
	python setup.py sdist upload
	python setup.py bdist_wheel upload

release-test: clean
	python setup.py sdist upload --repository https://testpypi.python.org/pypi
	python setup.py bdist_wheel upload --repository https://testpypi.python.org/pypi
	open https://testpypi.python.org/pypi/{{cookiecutter.repo_name}}

dist: clean
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean
	python setup.py install

lint:
	pylint {{ cookiecutter.repo_name }} tests

docs:
	rm -f docs/{{cookiecutter.repo_name}}.rst
	rm -f docs/modules.rst
	sphinx-apidoc -o docs/ {{cookiecutter.repo_name}}
	make -C docs clean
	make -C docs html
	open docs/_build/html/index.html	
