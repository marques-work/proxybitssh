# vim: ts=2 tw=2 noet ai

.DEFAULT_GOAL := help

.PHONY: help
help:                   ## Show this help message
	@grep -E '^[.a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN { FS = ":.*?## " }; { lines[FNR]=$$1":##"$$2; len=length($$1); if (len > max) max=len; ++c; } END { FS=":##";fmt="\033[36;1m%-"max"s\033[37;1m    %s\033[0m\n"; for(i=1;i<=c;++i){$$0=lines[i]; printf(fmt, $$1, $$2) } }'

.PHONY: multiarch-setup
multiarch-setup:        ## Setup docker buildx
	@multiarch/setup.sh

.PHONY: push
push: multiarch-setup  ## Build and push this multiarch image
	@docker buildx build --platform linux/arm64,linux/amd64 . -t invid/proxybitssh:$${VERSION:-latest} -t invid/proxybitssh:latest --push
