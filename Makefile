# Copyright 2021 - 2022 Matrix Origin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
ROOT_DIR = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: shfmt
shfmt:
	@cd $(ROOT_DIR) && shfmt -ci -kp -sr -bn -i 4 -w -l ./

.PHONY: shfmt-install
shfmt-install:
	@if which go >/dev/null 2>&1; then \
		echo "Installing shfmt using go..."; \
		go install mvdan.cc/sh/v3/cmd/shfmt@v3.11.0; \
	elif which apt-get >/dev/null 2>&1; then \
		echo "Installing shfmt using apt..."; \
		sudo apt-get update && sudo apt-get install -y shfmt; \
	else \
		echo "Error: No supported package manager found. Please install shfmt manually."; \
		exit 1; \
	fi