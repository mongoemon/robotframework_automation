#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_ios.sh
# Runs the Robot Framework test suite against an iOS simulator or real device.
#
# USAGE:
#   ./scripts/run_ios.sh                          # run all tests
#   ./scripts/run_ios.sh --tags smoke             # run tests tagged 'smoke'
#   ./scripts/run_ios.sh --suite 01_login_smoke   # run a specific suite file
#   ./scripts/run_ios.sh --tags regression --loglevel DEBUG
#
# OPTIONS:
#   --tags      TAG        Run only tests matching this tag (e.g. smoke, TC001)
#   --suite     SUITE      Run only the named suite file (no .robot extension needed)
#   --loglevel  LEVEL      Robot Framework log level: TRACE|DEBUG|INFO|WARN|ERROR (default: INFO)
#   --dryrun               Validate keywords without executing (Robot Framework --dryrun)
#   -h | --help            Show this help message
#
# PREREQUISITES:
#   1. macOS with Xcode installed and command-line tools active
#   2. Appium running: appium
#   3. iOS simulator booted OR real device connected
#   4. xcuitest driver installed: appium driver install xcuitest
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Defaults ──────────────────────────────────────────────────────────────────
PLATFORM="ios"
TAGS=""
SUITE=""
LOG_LEVEL="INFO"
DRY_RUN=false
APPIUM_URL="http://localhost:4723"
APPIUM_STATUS_ENDPOINT="${APPIUM_URL}/status"

# ── Resolve project root ──────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="${PROJECT_ROOT}/results/ios_${TIMESTAMP}"

# ── Parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tags)
      TAGS="$2"
      shift 2
      ;;
    --suite)
      SUITE="$2"
      shift 2
      ;;
    --loglevel)
      LOG_LEVEL="$2"
      shift 2
      ;;
    --dryrun)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown argument: $1${RESET}"
      echo "Run '$0 --help' for usage."
      exit 1
      ;;
  esac
done

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${BLUE}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Robot Framework Mobile Automation — iOS            ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "  ${BOLD}Platform:${RESET}    ${PLATFORM}"
echo -e "  ${BOLD}Timestamp:${RESET}   ${TIMESTAMP}"
echo -e "  ${BOLD}Output dir:${RESET}  ${OUTPUT_DIR}"
echo -e "  ${BOLD}Log level:${RESET}   ${LOG_LEVEL}"
[[ -n "$TAGS" ]]  && echo -e "  ${BOLD}Tags:${RESET}        ${TAGS}"
[[ -n "$SUITE" ]] && echo -e "  ${BOLD}Suite:${RESET}       ${SUITE}"
echo ""

# ── Pre-flight: Running on macOS? ─────────────────────────────────────────────
echo -e "${YELLOW}[1/4] Checking platform (iOS tests require macOS)...${RESET}"
if [[ "$(uname)" != "Darwin" ]]; then
  echo -e "${RED}      ERROR: iOS tests can only run on macOS.${RESET}"
  echo -e "      Current OS: $(uname)"
  exit 1
fi
echo -e "${GREEN}      macOS detected.${RESET}"

# ── Pre-flight: Xcode CLI tools ───────────────────────────────────────────────
echo -e "${YELLOW}[2/4] Checking for xcrun (Xcode command line tools)...${RESET}"
if ! command -v xcrun &> /dev/null; then
  echo -e "${RED}      ERROR: Xcode command line tools not found.${RESET}"
  echo -e "      Install them with:  ${BOLD}xcode-select --install${RESET}"
  exit 1
fi
echo -e "${GREEN}      Xcode CLI tools found: $(xcrun --version 2>&1 | head -1).${RESET}"

# ── Pre-flight: Appium running? ───────────────────────────────────────────────
echo -e "${YELLOW}[3/4] Checking Appium server at ${APPIUM_URL}...${RESET}"
if curl -sf "${APPIUM_STATUS_ENDPOINT}" > /dev/null 2>&1; then
  echo -e "${GREEN}      Appium is running.${RESET}"
else
  echo -e "${RED}      ERROR: Appium is NOT running.${RESET}"
  echo -e "      Start Appium in another terminal:  ${BOLD}appium${RESET}"
  exit 1
fi

# ── Pre-flight: iOS simulator or device booted? ───────────────────────────────
echo -e "${YELLOW}[4/4] Checking for booted iOS simulator or connected device...${RESET}"
BOOTED_SIM=$(xcrun simctl list devices 2>/dev/null | grep "Booted" || true)
REAL_DEVICES=$(xcrun xctrace list devices 2>/dev/null | grep "iPhone\|iPad" | grep -v "Simulator" || true)

if [[ -z "${BOOTED_SIM}" && -z "${REAL_DEVICES}" ]]; then
  echo -e "${RED}      ERROR: No iOS simulator is booted and no real device found.${RESET}"
  echo ""
  echo -e "      To start a simulator, run:"
  echo -e "        ${BOLD}xcrun simctl boot 'iPhone 15 Pro'${RESET}   (use exact name from xcrun simctl list)"
  echo -e "      OR open Xcode → Window → Devices and Simulators → start a simulator."
  echo ""
  echo -e "      Available simulators:"
  xcrun simctl list devices available 2>/dev/null | grep "iPhone\|iPad" | head -10 | awk '{print "        " $0}'
  exit 1
fi

if [[ -n "${BOOTED_SIM}" ]]; then
  echo -e "${GREEN}      Booted simulator(s):${RESET}"
  echo "${BOOTED_SIM}" | awk '{print "      " $0}'
fi
if [[ -n "${REAL_DEVICES}" ]]; then
  echo -e "${GREEN}      Connected real device(s):${RESET}"
  echo "${REAL_DEVICES}" | awk '{print "      " $0}'
fi

# ── Create output directory ───────────────────────────────────────────────────
mkdir -p "${OUTPUT_DIR}"

# ── Build Robot Framework command ─────────────────────────────────────────────
ROBOT_CMD=(
  robot
  --variable    "PLATFORM:${PLATFORM}"
  --outputdir   "${OUTPUT_DIR}"
  --log         "log.html"
  --report      "report.html"
  --output      "output.xml"
  --loglevel    "${LOG_LEVEL}"
  --timestampoutputs
)

[[ -n "$TAGS" ]]  && ROBOT_CMD+=(--include  "${TAGS}")
[[ -n "$SUITE" ]] && ROBOT_CMD+=(--suite    "${SUITE}")
[[ "$DRY_RUN" == "true" ]] && ROBOT_CMD+=(--dryrun)

# ── Run tests ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}Running tests...${RESET}"
echo -e "Command: ${BOLD}${ROBOT_CMD[*]} ${PROJECT_ROOT}/tests/${RESET}"
echo ""

EXIT_CODE=0
"${ROBOT_CMD[@]}" "${PROJECT_ROOT}/tests/" || EXIT_CODE=$?

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}${BOLD}══════════════════════════════════════════════════${RESET}"
if [[ "${EXIT_CODE}" -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}  ALL TESTS PASSED${RESET}"
elif [[ "${EXIT_CODE}" -eq 1 ]]; then
  echo -e "${RED}${BOLD}  SOME TESTS FAILED${RESET}"
else
  echo -e "${RED}${BOLD}  TEST EXECUTION ERROR (exit code: ${EXIT_CODE})${RESET}"
fi
echo -e "${BLUE}${BOLD}══════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${BOLD}HTML Report:${RESET}  ${OUTPUT_DIR}/report.html"
echo -e "  ${BOLD}Full Log:${RESET}     ${OUTPUT_DIR}/log.html"
echo ""
echo -e "  Open report in browser:"
echo -e "  ${BOLD}open ${OUTPUT_DIR}/report.html${RESET}"
echo ""

exit "${EXIT_CODE}"
