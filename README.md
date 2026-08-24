# ProvToolbox PROV-JSON Compatibility Tests

Automated compatibility tests for [ProvToolbox](https://github.com/lucmoreau/ProvToolbox) v2.2.4 against the [PROV-JSON W3C Member Submission](https://www.w3.org/Submission/2013/SUBM-prov-json-20130424/) (April 2013).

## What This Tests

Each test feeds a hand-crafted PROV-JSON document through ProvToolbox's JSON round-trip:

```
Input JSON → ProvDeserialiser → Document → ProvSerialiser → Output JSON → Compare
```

The test **passes** when the actual outcome matches the **expected** outcome — including expected crashes. A test that expects `PARSE_FAILED` **passes** if the parser crashes, and **fails** if it silently accepts the input.

### Verdict Types

| Verdict | Meaning |
|---|---|
| `ROUND_TRIP_IDENTICAL` | Output matches input (whitespace-normalized) |
| `ROUND_TRIP_CHANGED` | Parses and serializes, but output differs from input |
| `PARSE_FAILED` | Deserialization throws an exception |
| `SERIALIZE_FAILED` | Parses OK, but serialization throws an exception |

## Quick Start

### Prerequisites

- **Java 21+** (tested with OpenJDK 26)
- **ProvToolbox v2.2.4** — cloned and built with `mvn install`
- **Maven local repo** (`~/.m2/repository`) populated by the ProvToolbox build

### Setup

```bash
# Clone this repo
git clone https://github.com/Common-Provenance-Framework/provtoolbox-prov-json-compat.git
cd provtoolbox-prov-json-compat

# Place ProvToolbox next to this repo (or set PROVTOOLBOX_HOME)
# Expected layout:
#   parent/
#     ProvToolbox-master/    ← built with mvn install
#     provtoolbox-prov-json-compat/  ← this repo
```

### Run All Tests

```bash
./run_tests.sh
```

### Options

```
-s SECTION   Run only one section (e.g., -s 2.1-identifiers)
-t TEST_ID   Run only tests matching a string (e.g., -t 2.1-07)
-f           Show only failures
-v           Verbose — show full Java output for every test
-d           Show JSON diff for ROUND_TRIP_CHANGED tests
-h           Help
```

### Examples

```bash
# Run only bundle tests
./run_tests.sh -s 3.3-bundles

# Show failures only
./run_tests.sh -f

# Verbose output for a single test
./run_tests.sh -t 2.1-07 -v

# All tests with JSON diffs
./run_tests.sh -d
```

## Test Coverage

135 tests across 26 spec subsections:

| Section | Topic | Tests |
|---|---|---|
| 2.1 | Identifiers & Qualified Names | 11 |
| 2.2 | Data Typing & Internationalization | 28 |
| 3.1.1 | Entity | 21 |
| 3.1.2 | Agent | 13 |
| 3.1.3 | Activity | 13 |
| 3.2.1 | Generation | 10 |
| 3.2.2 | Usage | 5 |
| 3.2.3 | Communication | 2 |
| 3.2.4 | Start | 3 |
| 3.2.5 | End | 1 |
| 3.2.6 | Invalidation | 2 |
| 3.2.7 | Derivation | 3 |
| 3.2.8 | Attribution | 1 |
| 3.2.9 | Association | 3 |
| 3.2.10 | Delegation | 2 |
| 3.2.11 | Influence | 1 |
| 3.2.12 | Specialization | 1 |
| 3.2.13 | Alternate | 1 |
| 3.2.14 | Membership | 2 |
| 3.3 | Bundles | 6 |
| A.1 | Authors View (Appendix) | 1 |
| A.2 | Process View (Appendix) | 1 |
| A.3 | Attribution (Appendix) | 1 |
| B.1 | Dictionary Membership | 1 |
| B.2 | Dictionary Insertion | 1 |
| B.3 | Dictionary Removal | 1 |

## Results Summary

Actual ProvToolbox v2.2.4 verdict distribution across 135 tests:

- **ROUND_TRIP_IDENTICAL**: 22 tests (16%) — ProvToolbox handles these correctly
- **ROUND_TRIP_CHANGED**: 97 tests (72%) — data survives but output format differs
- **PARSE_FAILED**: 13 tests (10%) — input rejected (2 legitimately, 11 due to bugs)
- **SERIALIZE_FAILED**: 3 tests (2%) — parses OK but crashes on re-serialization

24 of 135 tests pass (18%). A test passes when ProvToolbox produces the spec-correct outcome.

Full results with input/output JSON for every test are in [compatibility_results.xlsx](compatibility_results.xlsx) (3 sheets: All Tests, Summary, Issues).

**19 distinct compatibility issues** documented in [ISSUES.md](ISSUES.md), cross-checked against the [PROV-JSON W3C spec](https://www.w3.org/Submission/2013/SUBM-prov-json-20130424/):
- 5 Critical (data loss or crashes on valid input)
- 8 High (format corruption or silent data changes)
- 2 Medium (ordering issues)
- 4 Low/Info (cosmetic differences)

## Repository Structure

```
provtoolbox-prov-json-compat/
├── run_tests.sh              ← Main test runner
├── README.md
├── ISSUES.md                 ← Full issue catalog (19 issues, spec cross-checked)
├── issues_report.xlsx        ← Issues-only report with severity, evidence, summaries
├── compatibility_results.xlsx ← Full results spreadsheet (all 135 tests with input/output JSON)
├── harness/
│   └── JsonRoundTrip.java    ← Round-trip test harness
└── tests/
    ├── manifest.tsv           ← Test metadata & expected outcomes
    ├── 2.1-identifiers/       ← Section test directories
    │   ├── 2.1-01_standard_qname.json
    │   ├── 2.1-02_implicit_prov_prefix.json
    │   ├── ...
    │   ├── RAW_LOG.txt        ← Raw test execution log
    │   └── TEST_PLAN.txt      ← Detailed test plan & analysis
    ├── 2.2-data-typing/
    ├── 3.1.1-entity/
    └── ...
```

## How Tests Work

1. **manifest.tsv** defines each test: section, test ID, expected verdict, related issue IDs, and a description.

2. **JsonRoundTrip.java** is a minimal Java harness that:
   - Reads a JSON file
   - Deserializes with `ProvDeserialiser`
   - Re-serializes with `ProvSerialiser`
   - Compares input vs output (whitespace-normalized)
   - Prints a verdict line: `VERDICT: <result>`

3. **run_tests.sh** runs each test, extracts the verdict, compares to expected, and reports pass/fail.

## Adding Tests

1. Create a JSON file in the appropriate section directory: `tests/<section>/<test_id>.json`
2. Add a line to `tests/manifest.tsv` with: section, test_id, expected_verdict, issue_ids, description
3. Run `./run_tests.sh -t <test_id>` to verify

## License

Test files and harness code are provided for compatibility testing purposes.
PROV-JSON spec content is per the W3C Member Submission license.
ProvToolbox is licensed under the MIT License.
