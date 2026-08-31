#!/usr/bin/env bash
# ============================================================================
#  PROV-JSON Compatibility Test Runner
#  ProvToolbox v2.2.4 vs PROV-JSON W3C Spec
#
#  Usage:  ./run_tests.sh [options]
#
#  Options:
#    -s SECTION   Run only tests from this section (e.g., "2.1-identifiers")
#    -t TEST_ID   Run only this specific test (e.g., "2.1-07")
#    -f           Show only failures
#    -v           Verbose — show full Java output for every test
#    -d           Show diff for ROUND_TRIP_CHANGED tests
#    -h           Show this help
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"
HARNESS_DIR="$SCRIPT_DIR/harness"
MANIFEST="$TESTS_DIR/manifest.tsv"

# --- Colors ---------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# --- Options --------------------------------------------------------------
FILTER_SECTION=""
FILTER_TEST=""
ONLY_FAILURES=false
VERBOSE=false
SHOW_DIFF=false

while getopts "s:t:fvdh" opt; do
  case $opt in
    s) FILTER_SECTION="$OPTARG" ;;
    t) FILTER_TEST="$OPTARG" ;;
    f) ONLY_FAILURES=true ;;
    v) VERBOSE=true ;;
    d) SHOW_DIFF=true ;;
    h)
      head -14 "$0" | tail -12
      exit 0
      ;;
    *)
      echo "Unknown option. Use -h for help."
      exit 1
      ;;
  esac
done

# --- Locate Java & ProvToolbox --------------------------------------------
if [ -n "${JAVA_HOME:-}" ]; then
  JAVA="$JAVA_HOME/bin/java"
  JAVAC="$JAVA_HOME/bin/javac"
else
  JAVA="$(command -v java 2>/dev/null || true)"
  JAVAC="$(command -v javac 2>/dev/null || true)"
fi

if [ -z "$JAVA" ] || [ ! -x "$JAVA" ]; then
  echo -e "${RED}ERROR: Java not found. Set JAVA_HOME or add java to PATH.${RESET}"
  exit 1
fi

# Look for ProvToolbox
TOOLBOX=""
for candidate in \
  "$SCRIPT_DIR/../ProvToolbox-master" \
  "$SCRIPT_DIR/ProvToolbox-master" \
  "$SCRIPT_DIR/Prov Toolbox vs JSON/ProvToolbox-master" \
  "$SCRIPT_DIR/../Prov Toolbox vs JSON/ProvToolbox-master" \
  "$HOME/Desktop/Prov Toolbox vs JSON/ProvToolbox-master" \
  "${PROVTOOLBOX_HOME:-/nonexistent}"; do
  if [ -d "$candidate/modules-core" ]; then
    TOOLBOX="$(cd "$candidate" && pwd)"
    break
  fi
done

if [ -z "$TOOLBOX" ]; then
  echo -e "${RED}ERROR: ProvToolbox not found.${RESET}"
  echo "Place ProvToolbox-master next to this repo, or set PROVTOOLBOX_HOME."
  exit 1
fi

M2="${HOME}/.m2/repository"

# --- Build classpath -------------------------------------------------------
CP="$TOOLBOX/modules-core/prov-jsonld/target/prov-jsonld-2.2.4.jar"
CP="$CP:$TOOLBOX/modules-core/prov-model/target/prov-model-2.2.4.jar"
CP="$CP:$M2/com/fasterxml/jackson/core/jackson-databind/2.21.2/jackson-databind-2.21.2.jar"
CP="$CP:$M2/com/fasterxml/jackson/core/jackson-core/2.21.2/jackson-core-2.21.2.jar"
CP="$CP:$M2/com/fasterxml/jackson/core/jackson-annotations/2.21/jackson-annotations-2.21.jar"
CP="$CP:$M2/org/apache/logging/log4j/log4j-api/2.25.5/log4j-api-2.25.5.jar"
CP="$CP:$M2/org/apache/logging/log4j/log4j-core/2.25.5/log4j-core-2.25.5.jar"
CP="$CP:$M2/org/apache/commons/commons-lang3/3.20.0/commons-lang3-3.20.0.jar"
CP="$CP:$M2/org/apache/commons/commons-collections4/4.5.0/commons-collections4-4.5.0.jar"
CP="$CP:$M2/commons-io/commons-io/2.21.0/commons-io-2.21.0.jar"
CP="$CP:$M2/jakarta/xml/bind/jakarta.xml.bind-api/4.0.0/jakarta.xml.bind-api-4.0.0.jar"
CP="$CP:$M2/jakarta/activation/jakarta.activation-api/2.1.0/jakarta.activation-api-2.1.0.jar"

# --- Compile harness if needed ---------------------------------------------
CLASS_FILE="$HARNESS_DIR/JsonRoundTrip.class"
SOURCE_FILE="$HARNESS_DIR/JsonRoundTrip.java"

if [ ! -f "$CLASS_FILE" ] || [ "$SOURCE_FILE" -nt "$CLASS_FILE" ]; then
  echo -e "${DIM}Compiling test harness...${RESET}"
  "$JAVAC" -cp "$CP" -d "$HARNESS_DIR" "$SOURCE_FILE" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to compile JsonRoundTrip.java${RESET}"
    exit 1
  fi
fi

CP="$CP:$HARNESS_DIR"

# --- Read manifest ---------------------------------------------------------
declare -a TEST_SECTIONS=()
declare -a TEST_IDS=()
declare -a TEST_EXPECTED=()
declare -a TEST_ISSUES=()
declare -a TEST_DESCS=()

while IFS=$'\t' read -r section test_id expected issues desc; do
  [[ "$section" =~ ^#.*$ ]] && continue
  [[ -z "$section" ]] && continue

  if [ -n "$FILTER_SECTION" ] && [ "$section" != "$FILTER_SECTION" ]; then
    continue
  fi
  if [ -n "$FILTER_TEST" ] && [[ "$test_id" != *"$FILTER_TEST"* ]]; then
    continue
  fi

  TEST_SECTIONS+=("$section")
  TEST_IDS+=("$test_id")
  TEST_EXPECTED+=("$expected")
  TEST_ISSUES+=("$issues")
  TEST_DESCS+=("$desc")
done < "$MANIFEST"

TOTAL=${#TEST_IDS[@]}

if [ "$TOTAL" -eq 0 ]; then
  echo -e "${YELLOW}No tests matched the filter.${RESET}"
  exit 0
fi

# --- Run tests -------------------------------------------------------------
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║  PROV-JSON Compatibility Tests — ProvToolbox v2.2.4            ║${RESET}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════════╣${RESET}"
echo -e "${BOLD}║  Tests: ${TOTAL}  |  ProvToolbox: ${TOOLBOX##*/}${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

PASS=0
FAIL=0
CURRENT_SECTION=""
SECTION_PASS=0
SECTION_FAIL=0
SECTION_TOTAL=0

declare -a FAIL_DETAILS=()

print_section_summary() {
  if [ -n "$CURRENT_SECTION" ]; then
    local pct=0
    if [ "$SECTION_TOTAL" -gt 0 ]; then
      pct=$(( SECTION_PASS * 100 / SECTION_TOTAL ))
    fi
    if [ "$SECTION_FAIL" -eq 0 ]; then
      echo -e "  ${DIM}Section total: ${GREEN}${SECTION_PASS}/${SECTION_TOTAL} passed (${pct}%)${RESET}"
    else
      echo -e "  ${DIM}Section total: ${SECTION_PASS}/${SECTION_TOTAL} passed, ${RED}${SECTION_FAIL} failed${RESET} ${DIM}(${pct}%)${RESET}"
    fi
    echo ""
  fi
}

for i in $(seq 0 $((TOTAL - 1))); do
  section="${TEST_SECTIONS[$i]}"
  test_id="${TEST_IDS[$i]}"
  expected="${TEST_EXPECTED[$i]}"
  issues="${TEST_ISSUES[$i]}"
  desc="${TEST_DESCS[$i]}"

  # Section header
  if [ "$section" != "$CURRENT_SECTION" ]; then
    print_section_summary
    CURRENT_SECTION="$section"
    SECTION_PASS=0
    SECTION_FAIL=0
    SECTION_TOTAL=0
    echo -e "${BOLD}${CYAN}── $section ──${RESET}"
  fi

  SECTION_TOTAL=$((SECTION_TOTAL + 1))

  # Find the JSON file
  json_file="$TESTS_DIR/$section/${test_id}.json"
  if [ ! -f "$json_file" ]; then
    # JSON file not found — automatic failure
    if [ "$ONLY_FAILURES" = true ] || [ "$ONLY_FAILURES" = false ]; then
      echo -e "  ${RED}FAIL${RESET}  ${test_id}  ${DIM}(file not found: ${json_file})${RESET}"
    fi
    FAIL=$((FAIL + 1))
    SECTION_FAIL=$((SECTION_FAIL + 1))
    FAIL_DETAILS+=("${test_id}|${section}|FILE_NOT_FOUND|${expected}|File not found: ${json_file}")
    continue
  fi

  # Run the test
  output=$("$JAVA" -cp "$CP" JsonRoundTrip "$json_file" 2>&1) || true

  # Extract actual verdict
  actual=$(echo "$output" | grep "^VERDICT:" | head -1 | sed 's/VERDICT: *//')

  if [ -z "$actual" ]; then
    actual="NO_VERDICT"
  fi

  # Compare actual vs expected
  if [ "$actual" = "$expected" ]; then
    PASS=$((PASS + 1))
    SECTION_PASS=$((SECTION_PASS + 1))
    if [ "$ONLY_FAILURES" = false ]; then
      echo -e "  ${GREEN}PASS${RESET}  ${test_id}  ${DIM}${expected}${RESET}"
    fi
  else
    FAIL=$((FAIL + 1))
    SECTION_FAIL=$((SECTION_FAIL + 1))
    echo -e "  ${RED}FAIL${RESET}  ${test_id}  expected=${YELLOW}${expected}${RESET}  actual=${RED}${actual}${RESET}"

    # Collect failure detail
    exception=""
    if [ "$actual" = "PARSE_FAILED" ] || [ "$actual" = "SERIALIZE_FAILED" ]; then
      exception=$(echo "$output" | grep "^EXCEPTION:" | head -1 | sed 's/EXCEPTION: *//')
    fi
    FAIL_DETAILS+=("${test_id}|${section}|${actual}|${expected}|${exception:-${desc}}")
  fi

  # Verbose mode: show full output
  if [ "$VERBOSE" = true ]; then
    echo -e "    ${DIM}--- output ---${RESET}"
    echo "$output" | sed 's/^/    /'
    echo -e "    ${DIM}--- end ---${RESET}"
  fi

  # Diff mode for ROUND_TRIP_CHANGED
  if [ "$SHOW_DIFF" = true ] && [ "$actual" = "ROUND_TRIP_CHANGED" ]; then
    output_json=$(echo "$output" | sed -n '/^--- OUTPUT JSON ---$/,/^--- END OUTPUT ---$/p' | sed '1d;$d')
    if [ -n "$output_json" ]; then
      echo -e "    ${DIM}--- diff (input vs output) ---${RESET}"
      diff --color=always <(python3 -m json.tool "$json_file" 2>/dev/null || cat "$json_file") \
           <(echo "$output_json" | python3 -m json.tool 2>/dev/null || echo "$output_json") \
           | head -30 | sed 's/^/    /' || true
      echo -e "    ${DIM}--- end diff ---${RESET}"
    fi
  fi
done

# Final section summary
print_section_summary

# --- Summary ---------------------------------------------------------------
echo -e "${BOLD}══════════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}RESULTS${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════════════════${RESET}"
echo ""

PCT=0
if [ "$TOTAL" -gt 0 ]; then
  PCT=$(( PASS * 100 / TOTAL ))
fi

echo -e "  Total:   ${BOLD}${TOTAL}${RESET}"
echo -e "  Passed:  ${GREEN}${BOLD}${PASS}${RESET}  ${DIM}(${PCT}%)${RESET}"
echo -e "  Failed:  ${RED}${BOLD}${FAIL}${RESET}  ${DIM}($((100 - PCT))%)${RESET}"
echo ""

if [ ${#FAIL_DETAILS[@]} -gt 0 ]; then
  echo -e "${BOLD}${RED}FAILED TESTS:${RESET}"
  echo -e "${DIM}──────────────────────────────────────────────────────────────${RESET}"
  printf "  ${BOLD}%-30s  %-22s  %-22s${RESET}\n" "TEST" "EXPECTED" "ACTUAL"
  echo -e "${DIM}──────────────────────────────────────────────────────────────${RESET}"

  for detail in "${FAIL_DETAILS[@]}"; do
    IFS='|' read -r f_id f_section f_actual f_expected f_reason <<< "$detail"
    printf "  %-30s  ${YELLOW}%-22s${RESET}  ${RED}%-22s${RESET}\n" "$f_id" "$f_expected" "$f_actual"
    if [ -n "$f_reason" ]; then
      echo -e "    ${DIM}→ ${f_reason}${RESET}"
    fi
    echo -e "    ${DIM}  file: tests/${f_section}/${f_id}.json${RESET}"
  done
  echo ""
fi

# --- Verdict summary by category ------------------------------------------
echo -e "${BOLD}VERDICT DISTRIBUTION:${RESET}"
ident_count=0; changed_count=0; parse_count=0; serial_count=0; other_count=0
for i in $(seq 0 $((TOTAL - 1))); do
  case "${TEST_EXPECTED[$i]}" in
    ROUND_TRIP_IDENTICAL) ident_count=$((ident_count + 1)) ;;
    ROUND_TRIP_CHANGED)   changed_count=$((changed_count + 1)) ;;
    PARSE_FAILED)         parse_count=$((parse_count + 1)) ;;
    SERIALIZE_FAILED)     serial_count=$((serial_count + 1)) ;;
    *)                    other_count=$((other_count + 1)) ;;
  esac
done
echo -e "  ${GREEN}ROUND_TRIP_IDENTICAL:${RESET}  ${ident_count}"
echo -e "  ${YELLOW}ROUND_TRIP_CHANGED:${RESET}   ${changed_count}"
echo -e "  ${RED}PARSE_FAILED:${RESET}         ${parse_count}"
echo -e "  ${RED}SERIALIZE_FAILED:${RESET}     ${serial_count}"
echo ""

# Exit code: 0 if all pass, 1 if any fail
if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}${FAIL} test(s) produced unexpected results.${RESET}"
  exit 1
else
  echo -e "${GREEN}All ${TOTAL} tests behaved as expected.${RESET}"
  exit 0
fi
