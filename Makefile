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
SHELL ?= bash
PREFIX ?= /usr/local
_PROJECT=evm-wallet
_PROJECT_NPM=$(_PROJECT).js
_NAMESPACE=themartiancompany
DOC_DIR=$(DESTDIR)$(PREFIX)/share/doc/$(_PROJECT)
USR_DIR=$(DESTDIR)$(PREFIX)
BIN_DIR=$(DESTDIR)$(PREFIX)/bin
LIB_DIR=$(DESTDIR)$(PREFIX)/lib/$(_PROJECT)
MAN_DIR?=$(DESTDIR)$(PREFIX)/share/man
NODE_DIR=$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT)
BUILD_NPM_DIR=build

_MAKE_LINK=\
  ln \
    -sv
_MAKE_EXE=\
  chmod \
    755
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

build-man:

	git \
	  submodule \
	    update \
	    --init \
	      "man" || \
	true; \
	_version="$$( \
	  npm \
	    view \
	      "$${PWD}" \
	      "version")"; \
	cd \
	  "man"; \
	make \
	  _VERSION="$${_version}" \
	  build-man
	mkdir \
	  -p \
	  "build/man"
	cp \
	  -r \
	  "man/build/"* \
	  "build/man"

build-npm:

	make \
	  build-man
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

build-webpack:

	cp \
	  -r \
	  "$(_PROJECT)" \
	  "dist" \
	  "lib$(_PROJECT)" \
	  "webpack.config.cjs" \
	  "build"
	_webpack=( \
	  "$$(command \
	        -v \
	        "webpack")"; \
	if [[ "${_webpack}" == "" ]]; then \
	  _webpack=(
	    npx
	      webpack); \
	fi; \
	cd \
	  "build"; \
	if [[ ! -e "fs-worker.js" ]]; then \
          "${_webpack[@]}" \
	    --mode \
	      'production' \
	    --config \
	    'fs-worker.webpack.config.cjs' \
	    --stats-error-details; \
	fi; \
	cp \
	  'fs-worker.js' \
	  'dist/$(_PROJECT)/fs-worker.js'; \
	cp \
	  'fs-worker.js' \
	  'dist/lib$(_PROJECT)/fs-worker.js'; \
	if [[ ! -e "$(_PROJECT).js" ]]; then \
          "${_webpack[@]}" \
	    --mode \
	      'production' \
	    --config \
	      'webpack.config.cjs' \
	    --stats-error-details; \
	fi; \
	cp \
	  "$(_PROJECT).js" \
	  "dist/$(_PROJECT)/$(_PROJECT).js"
	if [[ ! -e "lib$(_PROJECT).js" ]]; then \
          "${_webpack[@]}" \
	    --mode \
	      'production' \
	    --config \
	      'webpack.config.cjs' \
	    --stats-error-details; \
	fi; \
	cp \
	  "lib$(_PROJECT).js" \
	  "dist/lib$(_PROJECT)/lib$(_PROJECT).js"

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

	if [[ "$(_NPM)" == "false" ]]; then \
	  $(_INSTALL_DIR) \
	    "$(LIB_DIR)/nodejs" \
	  $(_INSTALL_DIR) \
	    "$(BIN_DIR)"; \
	  cp \
	    -r \
	    $$(printf \
	         "$${PWD}/%s " \
	         $$(cat \
	              "$${PWD}/package.json" | \
	              jq \
	                --raw-output \
	                '.files[]')) \
	    "$(LIB_DIR)/nodejs"; \
	  $(_MAKE_EXE) \
	    "$(LIB_DIR)/nodejs/$(_PROJECT)"; \
	  rm \
	    -vf \
	    "$(BIN_DIR)/$(_PROJECT_NPM)"; \
	  if [[ ! -s "$(BIN_DIR)/$(_PROJECT)" && \
	        ! -e "$(BIN_DIR)/$(_PROJECT)" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/$(_PROJECT)" \
	      "$(BIN_DIR)/$(_PROJECT)"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/$(_PROJECT_NPM)" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/$(_PROJECT)" \
	      "$(BIN_DIR)/$(_PROJECT_NPM)"; \
	  fi; \
	  $(_MAKE_EXE) \
	    "$(LIB_DIR)/nodejs/lib/block-get"; \
	  if [[ ! -s "$(BIN_DIR)/block" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/block-get" \
	      "$(BIN_DIR)/block"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/block.js" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/block-get" \
	      "$(BIN_DIR)/block.js"; \
	  fi; \
	  $(_MAKE_EXE) \
	    "$(LIB_DIR)/nodejs/lib/block-number-get"; \
	  if [[ ! -s "$(BIN_DIR)/block-number.js" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/block-number-get" \
	      "$(BIN_DIR)/block-number.js"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/block-number" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/block-number-get" \
	      "$(BIN_DIR)/block-number"; \
	  fi; \
	  $(_MAKE_EXE) \
	    "$(LIB_DIR)/nodejs/lib/address-get"; \
	  if [[ ! -s "$(BIN_DIR)/eoa-fingerprint" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/address-get" \
	      "$(BIN_DIR)/eoa-fingerprint"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/eoa-fingerprint.js" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/address-get" \
	      "$(BIN_DIR)/eoa-fingerprint.js"; \
	  fi; \
	  $(_MAKE_EXE) \
	    "$(LIB_DIR)/nodejs/lib/ethers-to-wei"; \
	  if [[ ! -s "$(BIN_DIR)/ether-to-wei" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/ethers-to-wei" \
	      "$(BIN_DIR)/ether-to-wei"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/ether2wei" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/ethers-to-wei" \
	      "$(BIN_DIR)/ether2wei"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/ether2wei.js" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/ethers-to-wei" \
	      "$(BIN_DIR)/ether2wei.js"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/ether-to-wei.js" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/ethers-to-wei" \
	      "$(BIN_DIR)/ether-to-wei.js"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/ethers-to-wei" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/ethers-to-wei" \
	      "$(BIN_DIR)/ethers-to-wei"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/ethers-to-wei.js" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/ethers-to-wei" \
	      "$(BIN_DIR)/ethers-to-wei.js"; \
	  fi; \
	  $(_MAKE_EXE) \
	    "$(LIB_DIR)/nodejs/lib/balance-get"; \
	  if [[ ! -s "$(BIN_DIR)/gas-balance" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/balance-get" \
	      "$(BIN_DIR)/gas-balance"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/gas-balance.js" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/balance-get" \
	      "$(BIN_DIR)/gas-balance.js"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/gas-level" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/balance-get" \
	      "$(BIN_DIR)/gas-level"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/gas-level.js" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/balance-get" \
	      "$(BIN_DIR)/gas-level.js"; \
	  fi; \
	  $(_MAKE_EXE) \
	    "$(LIB_DIR)/nodejs/lib/balance-send"; \
	  if [[ ! -s "$(BIN_DIR)/gas-transfer" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/balance-send" \
	      "$(BIN_DIR)/gas-transfer"; \
	  fi; \
	  if [[ ! -s "$(BIN_DIR)/gas-transfer.js" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs/lib/balance-send" \
	      "$(BIN_DIR)/gas-transfer.js"; \
	  fi; \
	  rm \
	    "$(LIB_DIR)/node_modules" || \
	    true; \
	  if [[ ! -s "$(LIB_DIR)/node_modules" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/node_modules" \
	      "$(LIB_DIR)/nodejs/node_modules"; \
	  fi; \
	  rm \
	    -rf \
	    "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT)" \
	    "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)"; \
	  if [[ ! -s "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT)" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs" \
	      "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT)"; \
	  fi; \
	  if [[ ! -s "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)" ]]; then \
	    $(_MAKE_LINK) \
	      "$(PREFIX)/lib/$(_PROJECT)/nodejs" \
	      "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)" || \
	      true; \
	  fi; \
	elif [[ "$(_NPM)" == "true" ]]; then \
	  make \
	    install-npm; \
	  $(_MAKE_LINK) \
	    "$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)" \
	    "$(LIB_DIR)/nodejs" || \
	  true; \
	fi

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
          "$(PREFIX)/lib/node_modules/$(_PROJECT)" \
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

uninstall-man:

	rm  \
	  -vrf \
	  "$(MAN_DIR)/man1/$(_PROJECT).1"
	  "$(MAN_DIR)/man1/$(_PROJECT_NPM).1"

uninstall-scripts:

	rm  \
	  -rfv \
	  "$(BIN_DIR)/$(_PROJECT)" \
	  "$(BIN_DIR)/$(_PROJECT_NPM)" \
	  "$(BIN_DIR)/block"{"",".js"} \
	  "$(BIN_DIR)/block-number"{"",".js"} \
	  "$(BIN_DIR)/$(_PROJECT_NPM)" \
	  "$(BIN_DIR)/eoa-fingerprint"{"",".js"} \
	  "$(BIN_DIR)/gas-balance"{"",".js"} \
	  "$(BIN_DIR)/gas-level"{"",".js"} \
	  "$(BIN_DIR)/gas-transfer"{"",".js"} \
	  "$(LIB_DIR)/nodejs" \
	  "$(DESTDIR)$(PREFIX)/lib/$(_PROJECT_NPM)" \
	  "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT_NPM)" \
	  "$(DESTDIR)$(PREFIX)/lib/node_modules/$(_PROJECT)"

.PHONY: check build build-man build-npm build-webpack install install-doc install-man install-npm install-scripts shellcheck uninstall-man uninstall-scripts
