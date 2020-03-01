# It's necessary to set this because some environments don't link sh -> bash.
SHELL          := /bin/bash


# .PHONY: all
# linux: build_linux

.PHONY: index
index:
	script/update-index.sh
	
.PHONY: index_zh
index_zh:
	script/update-index.sh zh

.PHONY: index_en
index_en:
	script/update-index.sh en

.PHONY: update
update:
	script/deploy.sh