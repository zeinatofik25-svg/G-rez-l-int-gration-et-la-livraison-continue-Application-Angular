#!/usr/bin/env bash
set -u

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$PROJECT_DIR/test-results"

log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1"; }

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log_error "Missing dependency: '$1'. $2"
    exit 2
  fi
}

copy_junit_reports() {
  local source_dir="$1"
  local target_dir="$2"
  local count=0

  mkdir -p "$target_dir"
  while IFS= read -r -d '' report; do
    cp "$report" "$target_dir/$(basename "$report")"
    count=$((count + 1))
  done < <(find "$source_dir" -type f -name '*.xml' -print0 2>/dev/null)

  echo "$count"
}

if [ ! -f "$PROJECT_DIR/package.json" ]; then
  log_error "Unsupported project: package.json was not found."
  exit 2
fi

require_command npm "Install Node.js and npm, then add them to PATH."

rm -rf "$RESULTS_DIR" "$PROJECT_DIR/reports"
mkdir -p "$RESULTS_DIR"

log_info "Detected Angular project. Running unit tests..."
(
  cd "$PROJECT_DIR" || exit 99
  npm test -- --watch=false
)
test_exit=$?

report_count="$(copy_junit_reports "$PROJECT_DIR/reports" "$RESULTS_DIR/angular")"
if [ "$report_count" -eq 0 ]; then
  log_error "No JUnit XML report was generated."
  exit 1
fi

if [ "$test_exit" -ne 0 ]; then
  log_error "Angular tests failed with exit code $test_exit."
  exit "$test_exit"
fi

log_info "Angular tests passed. JUnit reports: $RESULTS_DIR/angular"
