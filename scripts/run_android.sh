#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_android.sh
# Runs the Robot Framework test suite against an Android device or emulator.
#
# USAGE:
#   ./scripts/run_android.sh                          # run all tests
#   ./scripts/run_android.sh --tags smoke             # run tests tagged 'smoke'
#   ./scripts/run_android.sh --suite 01_login_smoke   # run a specific suite file
#   ./scripts/run_android.sh --tags regression --loglevel DEBUG
#
# OPTIONS:
#   --tags      TAG        Run only tests matching this tag (e.g. smoke, TC001)
#   --suite     SUITE      Run only the named suite file (no .robot extension needed)
#   --loglevel  LEVEL      Robot Framework log level: TRACE|DEBUG|INFO|WARN|ERROR (default: INFO)
#   --dryrun               Validate keywords without executing (Robot Framework --dryrun)
#   -h | --help            Show this help message
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colours for terminal output ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Defaults ──────────────────────────────────────────────────────────────────
PLATFORM="android"
TAGS=""
SUITE=""
LOG_LEVEL="INFO"
DRY_RUN=false
APPIUM_URL="http://localhost:4723"
APPIUM_STATUS_ENDPOINT="${APPIUM_URL}/status"

# ── Resolve project root (works whether called from any directory) ─────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="${PROJECT_ROOT}/results/android_${TIMESTAMP}"

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
echo "║   Robot Framework Mobile Automation — Android        ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "  ${BOLD}Platform:${RESET}    ${PLATFORM}"
echo -e "  ${BOLD}Timestamp:${RESET}   ${TIMESTAMP}"
echo -e "  ${BOLD}Output dir:${RESET}  ${OUTPUT_DIR}"
echo -e "  ${BOLD}Log level:${RESET}   ${LOG_LEVEL}"
[[ -n "$TAGS" ]]  && echo -e "  ${BOLD}Tags:${RESET}        ${TAGS}"
[[ -n "$SUITE" ]] && echo -e "  ${BOLD}Suite:${RESET}       ${SUITE}"
echo ""

# ── Pre-flight: Appium running? ───────────────────────────────────────────────
echo -e "${YELLOW}[1/3] Checking Appium server at ${APPIUM_URL}...${RESET}"
if curl -sf "${APPIUM_STATUS_ENDPOINT}" > /dev/null 2>&1; then
  echo -e "${GREEN}      Appium is running.${RESET}"
else
  echo -e "${RED}      ERROR: Appium is NOT running.${RESET}"
  echo -e "      Start Appium in another terminal with:  ${BOLD}appium${RESET}"
  echo -e "      Then re-run this script."
  exit 1
fi

# ── Pre-flight: Android device connected? ─────────────────────────────────────
echo -e "${YELLOW}[2/3] Checking for connected Android device / emulator...${RESET}"
if ! command -v adb &> /dev/null; then
  echo -e "${RED}      ERROR: 'adb' not found in PATH.${RESET}"
  echo -e "      Install Android SDK and add platform-tools to PATH."
  echo -e "      See docs/SETUP_GUIDE.md for instructions."
  exit 1
fi

DEVICE_COUNT=$(adb devices 2>/dev/null | grep -c "device$" || true)
if [[ "${DEVICE_COUNT}" -eq 0 ]]; then
  echo -e "${RED}      ERROR: No Android device/emulator detected.${RESET}"
  echo -e "      Start an emulator:  ${BOLD}emulator -avd Pixel_6_API_33${RESET}"
  echo -e "      Or connect a real device via USB and run: ${BOLD}adb devices${RESET}"
  exit 1
fi
echo -e "${GREEN}      Found ${DEVICE_COUNT} Android device(s).${RESET}"
adb devices | grep -v "List of" | grep "device$" | awk '{print "      Device: " $1}'

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
echo -e "${YELLOW}[3/3] Running tests...${RESET}"
echo -e "      Command: ${BOLD}${ROBOT_CMD[*]} ${PROJECT_ROOT}/tests/${RESET}"
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
