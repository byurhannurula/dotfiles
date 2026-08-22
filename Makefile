# =============================================================================
# dotfiles — macOS bootstrap
#   run `make` or `make help` for the command list
# =============================================================================

.DEFAULT_GOAL := help
.PHONY: help capture drift sync cleanup rebuild check diff update gens rollback tree hooks perms fmt lint scan signing-init signing signing-keys signing-test

FLAKE := .

help: ## show this help
	@echo ""
	@echo "  \033[1mdotfiles\033[0m — declarative macOS setup"
	@echo ""
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'
	@echo ""

## ---- capture & reconcile ---------------------------------------------------

capture: ## snapshot this Mac into capture-<date>/
	@bash ./scripts/capture.sh

drift: ## what's installed but not declared (pre-flight before rebuild)
	@bash ./scripts/drift.sh

sync: ## capture + drift + commit — run every few months
	@bash ./scripts/sync.sh

cleanup: ## dry-run disk cleanup (use `make cleanup-go` to apply)
	@bash ./scripts/cleanup.sh

cleanup-go: ## actually delete what `make cleanup` listed
	@bash ./scripts/cleanup.sh --go

## ---- nix -------------------------------------------------------------------

rebuild: ## apply the config to this machine
	@sudo darwin-rebuild switch --flake $(FLAKE)

check: ## dry-run the config, catch errors without applying
	@darwin-rebuild check --flake $(FLAKE)

diff: ## show what a rebuild would change
	@darwin-rebuild build --flake $(FLAKE) && nvd diff /run/current-system result

update: ## bump flake.lock to newer nixpkgs (do this rarely — grows /nix)
	@nix flake update --flake $(FLAKE)

gens: ## list generations
	@darwin-rebuild --list-generations

rollback: ## revert to the previous generation
	@sudo darwin-rebuild --rollback

## ---- misc ------------------------------------------------------------------

hooks: ## install the pre-commit secret scanner
	@chmod +x .githooks/pre-commit scripts/*.sh 2>/dev/null || true
	@git config core.hooksPath .githooks && echo "✓ hooks installed (.githooks/)"

perms: ## restore the executable bit on all scripts
	@chmod +x scripts/*.sh .githooks/pre-commit && ls -l scripts/*.sh | awk '{print "  "$$1"  "$$NF}'

signing-init: ## turn on commit signing NOW (no nix needed)
	@bash ./scripts/signing.sh init

signing: ## show commit-signing status
	@bash ./scripts/signing.sh status

signing-keys: ## list signing-capable public keys
	@bash ./scripts/signing.sh keys

signing-test: ## make a signed test commit and verify it
	@bash ./scripts/signing.sh test

scan: ## scan git history for committed secrets
	@gitleaks detect --source . --redact --config .gitleaks.toml -v

fmt: ## format all .nix files
	@nixfmt $$(find . -name '*.nix' -not -path './legacy/*')

lint: ## lint nix + shell
	@deadnix --fail $$(find . -name '*.nix' -not -path './legacy/*') || true
	@statix check . || true
	@shellcheck -S warning scripts/*.sh .githooks/pre-commit || true

tree: ## show repo layout
	@find . -path ./.git -prune -o -path './capture-2*' -prune -o -print \
	  | sed 's|^\./||' | sort | head -50
