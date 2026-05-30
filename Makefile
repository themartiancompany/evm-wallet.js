# SPDX-License-Identifier: AGPL-3.0

#    -----------------------------------------------------
#    Copyright © 2024, 2025, 2026  Pellegrino Prevete
#
#    All rights reserved
#    -----------------------------------------------------
#
#    This program is free software: you can redistribute
#    it and/or modify it under the terms of the
#    GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of
#    the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it
#    will be useful, but WITHOUT ANY WARRANTY;
#    without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU Affero General Public License for
#    more details.
#
#    You should have received a copy of the
#    GNU Affero General Public License
#    along with this program.
#    If not, see <https://www.gnu.org/licenses/>.

_NPM ?= true
SHELL=bash
PREFIX ?= /usr/local
_PROJECT=evm-wallet
_PROJECT_NPM=$(_PROJECT).js
_NAMESPACE=themartiancompany
DOC_DIR=$(DESTDIR)$(PREFIX)/share/doc/$(_PROJECT)
USR_DIR=$(DESTDIR)$(PREFIX)
BIN_DIR=$(DESTDIR)$(PREFIX)/bin
LIB_DIR=$(DESTDIR)$(PREFIX)/lib/$(_PROJECT)
MAN_DIR?=$(DESTDIR)$(PREFIX)/share/man
NODE_DIR=$(PREFIX)/lib/node_modules/$(_PROJECT)
BUILD_NPM_DIR=build

_INSTALL_FILE=\
  install \
    -vDm644
_INSTALL_EXE=\
  install \
    -vDm755
_INSTALL_DIR=\
  install \
    -vdm755

DOC_FILES=\
  $(wildcard \
      *.rst) \
  $(wildcard \
      *.md)
NPM_FILES=\
  "README.md" \
  "COPYING" \
  "AUTHORS.rst" \
  "dist" \
  "lib" \
  "lib$(_PROJECT)" \
  "lib$(_PROJECT).webpack.config.cjs" \
  "$(_PROJECT)" \
  "eslint.config.mjs" \
  "fs-worker.webpack.config.cjs" \
  "package.json" \
  "webpack.config.cjs"

all: build-man build-npm

check: eslint

eslint:

	npm \
	  install \
	  --save-dev; \
	npx \
	  eslint \
	    "."

install: install-scripts install-doc install-examples install-man

install-scripts:

	$(_INSTALL_DIR) \
	  "$(LIB_DIR)/node"
	for _file in $(NPM_FILES); do
	  $(_INSTALL_FILE) \
	    "$${_file}" \
	    "$(LIB_DIR)/node/$${_file}"; \
	done
	# ln \
	#   -s \
	#   "$(PREFIX)/lib/$(_PROJECT_NPM)/node/lib$(_PROJECT_NPM)" \
	#   "$(LIB_DIR)/$(_PROJECT_NPM)-js" || \
	# true

build-man:

	git \
	  submodule \
	    update \
	    --init \
	      "man" || \
	true; \
	cd \
	  "man"; \
	_tag="$$( \
	  git \
	    tag | \
	    sort \
	      -V | \
              head \
	        -n \
	          1)"; \
	_TAG="${_tag}" \
	make \
	  build-man
	mkdir \
	  -p \
	  "build/man"

build-npm:

	if [[ ! -d "build/man" ]]; then \
	  mkdir \
	    -p \
	    "build/man"
	  make \
	    build-man;
	  cp \
	    -r \
	    "man/build/*" \
	    "build/man"; \
	fi
	for _file in $(NPM_FILES); do \
	  if [[ -d "$${_file}" ]]; then \
	    mkdir \
	      -p \
	      "build/$${_file}"; \
	    cp \
	      -r \
	      "$${_file}/"* \
	      "build/$${_file}"; \
	  elif [[ -e "$${_file}" ]]; then \
	    cp \
	      -r \
	      "$${_file}" \
	      "build"; \
	  fi; \
	done
	cd \
	  "build"; \
	_version="$$( \
	  npm \
	    view \
	      "$${PWD}" \
	      "version")"; \
	npm \
	  install \
	  --include="optional"; \
	npm \
	  run \
	    "build"; \
	npm \
	  pack; \
	mv \
	  "$(_PROJECT_NPM)-$${_version}.tgz" \
	  ".."

install-npm:

	_npm_opts=( \
	  -g \
	  --prefix \
	    '$(USR_DIR)' \
	); \
	_version="$$( \
	  npm \
	    view \
	      "$${PWD}" \
	      "version")"; \
	npm \
	  install \
	    "$${_npm_opts[@]}" \
	    "$(_PROJECT_NPM)-$${_version}.tgz"; \
	$(_INSTALL_DIR) \
	  "$(DESTDIR)$(PREFIX)/lib"; \
	ln \
	  -s \
	  "$(NODE_DIR)" \
	  "$(LIB_DIR)" || \
	true

publish-npm:

	cd \
	  "build"; \
	npm \
	  publish \
	  --access \
	    "public"

install-doc:

	$(_INSTALL_FILE) \
	  $(DOC_FILES) \
	  -t \
	  $(DOC_DIR)

install-man:

	cd \
	  "man"; \
	make \
	  install-man

.PHONY: check build-man build-npm install install-doc install-man install-npm install-scripts shellcheck
