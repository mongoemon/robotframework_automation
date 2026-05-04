# ─────────────────────────────────────────────────────────────────────────────
# Robot Framework Mobile Automation — Makefile
#
# Usage:
#   make install          Install Python dependencies
#   make android          Run all tests on Android
#   make ios              Run all tests on iOS
#   make smoke-android    Run smoke tests on Android
#   make smoke-ios        Run smoke tests on iOS
#   make regression-android  Run regression tests on Android
#   make clean            Delete all generated results
#   make check-appium     Verify Appium is running
# ─────────────────────────────────────────────────────────────────────────────

PYTHON       := python3
PIP          := pip3
ROBOT        := robot
RESULTS_DIR  := results
TIMESTAMP    := $(shell date +%Y%m%d_%H%M%S)
LOG_LEVEL    := INFO

# Default output directory includes a timestamp so runs don't overwrite each other
OUTPUT_DIR   := $(RESULTS_DIR)/run_$(TIMESTAMP)

.DEFAULT_GOAL := help

# ── Setup ─────────────────────────────────────────────────────────────────────

.PHONY: install
install:  ## Install all Python dependencies into the current environment
	$(PIP) install -r requirements.txt
	@echo "Dependencies installed. Run 'make check-appium' next."

.PHONY: venv
venv:  ## Create a virtual environment at .venv and install dependencies
	$(PYTHON) -m venv .venv
	.venv/bin/pip install --upgrade pip
	.venv/bin/pip install -r requirements.txt
	@echo "Virtual environment ready. Activate with: source .venv/bin/activate"

# ── Health Checks ─────────────────────────────────────────────────────────────

.PHONY: check-appium
check-appium:  ## Verify Appium server is running on localhost:4723
	@curl -s http://localhost:4723/status | python3 -m json.tool > /dev/null 2>&1 \
		&& echo "Appium is running." \
		|| (echo "ERROR: Appium is NOT running. Start it with: appium" && exit 1)

.PHONY: check-android
check-android: check-appium  ## Check Appium + connected Android device/emulator
	@adb devices | grep -v "List of" | grep "device$$" > /dev/null 2>&1 \
		&& echo "Android device found." \
		|| (echo "ERROR: No Android device detected. Start emulator or connect device." && exit 1)

# ── Android Test Runs ────────────────────────────────────────────────────────

.PHONY: android
android: check-android  ## Run ALL tests on Android
	mkdir -p $(OUTPUT_DIR)
	PLATFORM=android $(ROBOT) \
		--variable PLATFORM:android \
		--outputdir $(OUTPUT_DIR) \
		--log log.html \
		--report report.html \
		--output output.xml \
		--loglevel $(LOG_LEVEL) \
		tests/
	@echo "Results saved to: $(OUTPUT_DIR)"

.PHONY: smoke-android
smoke-android: check-android  ## Run SMOKE tests on Android
	mkdir -p $(OUTPUT_DIR)
	PLATFORM=android $(ROBOT) \
		--variable PLATFORM:android \
		--include smoke \
		--outputdir $(OUTPUT_DIR) \
		--log log.html \
		--report report.html \
		--output output.xml \
		--loglevel $(LOG_LEVEL) \
		tests/
	@echo "Smoke results saved to: $(OUTPUT_DIR)"

.PHONY: regression-android
regression-android: check-android  ## Run REGRESSION tests on Android
	mkdir -p $(OUTPUT_DIR)
	PLATFORM=android $(ROBOT) \
		--variable PLATFORM:android \
		--include regression \
		--outputdir $(OUTPUT_DIR) \
		--log log.html \
		--report report.html \
		--output output.xml \
		--loglevel $(LOG_LEVEL) \
		tests/
	@echo "Regression results saved to: $(OUTPUT_DIR)"

# ── iOS Test Runs ─────────────────────────────────────────────────────────────

.PHONY: ios
ios: check-appium  ## Run ALL tests on iOS (simulator/device must already be booted)
	mkdir -p $(OUTPUT_DIR)
	PLATFORM=ios $(ROBOT) \
		--variable PLATFORM:ios \
		--outputdir $(OUTPUT_DIR) \
		--log log.html \
		--report report.html \
		--output output.xml \
		--loglevel $(LOG_LEVEL) \
		tests/
	@echo "Results saved to: $(OUTPUT_DIR)"

.PHONY: smoke-ios
smoke-ios: check-appium  ## Run SMOKE tests on iOS
	mkdir -p $(OUTPUT_DIR)
	PLATFORM=ios $(ROBOT) \
		--variable PLATFORM:ios \
		--include smoke \
		--outputdir $(OUTPUT_DIR) \
		--log log.html \
		--report report.html \
		--output output.xml \
		--loglevel $(LOG_LEVEL) \
		tests/
	@echo "Smoke results saved to: $(OUTPUT_DIR)"

.PHONY: regression-ios
regression-ios: check-appium  ## Run REGRESSION tests on iOS
	mkdir -p $(OUTPUT_DIR)
	PLATFORM=ios $(ROBOT) \
		--variable PLATFORM:ios \
		--include regression \
		--outputdir $(OUTPUT_DIR) \
		--log log.html \
		--report report.html \
		--output output.xml \
		--loglevel $(LOG_LEVEL) \
		tests/
	@echo "Regression results saved to: $(OUTPUT_DIR)"

# ── Filtering by Tag ──────────────────────────────────────────────────────────

# Example: make run-tag PLATFORM=android TAG=TC001
.PHONY: run-tag
run-tag:  ## Run tests matching a specific tag — usage: make run-tag PLATFORM=android TAG=TC001
	mkdir -p $(OUTPUT_DIR)
	$(ROBOT) \
		--variable PLATFORM:$(PLATFORM) \
		--include $(TAG) \
		--outputdir $(OUTPUT_DIR) \
		--loglevel $(LOG_LEVEL) \
		tests/

# ── Cleanup ───────────────────────────────────────────────────────────────────

.PHONY: clean
clean:  ## Delete all Robot Framework output files (keeps results/.gitkeep)
	find $(RESULTS_DIR) -name "*.html" -delete
	find $(RESULTS_DIR) -name "*.xml" -delete
	find $(RESULTS_DIR) -name "*.log" -delete
	find $(RESULTS_DIR) -name "*.png" -delete
	find $(RESULTS_DIR) -type d -empty -not -name "results" -delete
	@echo "Results cleaned."

.PHONY: clean-venv
clean-venv:  ## Remove the virtual environment
	rm -rf .venv
	@echo ".venv removed."

# ── Help ──────────────────────────────────────────────────────────────────────

.PHONY: help
help:  ## Show this help message
	@echo ""
	@echo "Robot Framework Mobile Automation"
	@echo "══════════════════════════════════"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
