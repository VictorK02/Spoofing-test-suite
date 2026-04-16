#!/usr/bin/env bash
set -euo pipefail

# SMTP spoofing test suite for a local/owned lab.
#
# Assumptions based on your message:
#   - authenticated sender account: vagrant@mysender.com
#   - recipient mailbox:          vagrant@myreceiver.com
#   - test domains:               mysender.com / myreceiver.com
#
# IMPORTANT:
#   - Edit SMTP_SERVER / SUBMISSION_SERVER to match your lab.
#   - If you actually meant mail.mysender.com or mail.myreceiver.com, update below.
#   - These tests are meant for a closed environment you control.

############################
# Config
############################

# Receiving SMTP server under test (port 25 tests)
SMTP_SERVER="${SMTP_SERVER:-localhost}"
SMTP_PORT="${SMTP_PORT:-25}"

# Submission server under test (port 587 tests)
SUBMISSION_SERVER="${SUBMISSION_SERVER:-localhost}"
SUBMISSION_PORT="${SUBMISSION_PORT:-587}"

# Authenticated account
AUTH_USER="${AUTH_USER:-vagrant@mysender.com}"
AUTH_PASS="${AUTH_PASS:-changeme}"

# Mailboxes / domains
RECIPIENT="${RECIPIENT:-vagrant@myreceiver.com}"
LEGIT_SENDER="${LEGIT_SENDER:-vagrant@mysender.com}"
INTERNAL_ALT_SENDER="${INTERNAL_ALT_SENDER:-admin@mysender.com}"
RECEIVER_DOMAIN_SENDER="${RECEIVER_DOMAIN_SENDER:-admin@myreceiver.com}"
EXTERNAL_SENDER="${EXTERNAL_SENDER:-attacker@evil.test}"

# TLS / auth knobs
AUTH_TYPE="${AUTH_TYPE:-LOGIN}"      # LOGIN, PLAIN, CRAM-MD5, etc.
TLS_OPT="${TLS_OPT:---tls}"          # for submission tests
TIMEOUT="${TIMEOUT:-20}"

# Output
OUT_DIR="${OUT_DIR:-results}"
mkdir -p "$OUT_DIR"

############################
# Helpers
############################

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

have_swaks() {
  command -v swaks >/dev/null 2>&1
}

run_test() {
  local name="$1"
  shift

  local outfile="$OUT_DIR/${name}.txt"

  echo "============================================================"
  echo "[$(timestamp)] RUNNING: $name"
  echo "Output: $outfile"
  echo "============================================================"

  {
    echo "# Test: $name"
    echo "# Time: $(timestamp)"
    echo "# Command:"
    printf '%q ' "$@"
    echo
    echo
    "$@"
  } >"$outfile" 2>&1 || true

  echo "Saved: $outfile"
  echo
}

usage() {
  cat <<EOF
Usage:
  $(basename "$0") all
  $(basename "$0") list
  $(basename "$0") <test_name>

Examples:
  AUTH_PASS='secret' SMTP_SERVER='mail.myreceiver.com' SUBMISSION_SERVER='mail.mysender.com' $(basename "$0") all
  $(basename "$0") unauth_internal_header_spoof
  $(basename "$0") auth_spoof_other_internal_user

Available tests:
  unauth_internal_header_spoof
  unauth_direct_internal_mailfrom
  open_relay_external_to_external
  envelope_header_mismatch
  display_name_spoof
  duplicate_from_headers
  from_whitespace_variant
  mixed_case_header_name
  encoded_display_name
  malformed_helo
  submission_without_tls
  auth_legit_send
  auth_spoof_other_internal_user
  auth_spoof_receiver_domain_user
EOF
}

############################
# Tests
############################

test_unauth_internal_header_spoof() {
  run_test "unauth_internal_header_spoof" \
    swaks \
      --server "$SMTP_SERVER" \
      --port "$SMTP_PORT" \
      --timeout "$TIMEOUT" \
      --to "$RECIPIENT" \
      --from "$EXTERNAL_SENDER" \
      --header "From: $INTERNAL_ALT_SENDER" \
      --header "Subject: [TEST1] unauth internal header spoof" \
      --body "Unauthenticated sender with internal From header."
}

test_unauth_direct_internal_mailfrom() {
  run_test "unauth_direct_internal_mailfrom" \
    swaks \
      --server "$SMTP_SERVER" \
      --port "$SMTP_PORT" \
      --timeout "$TIMEOUT" \
      --to "$RECIPIENT" \
      --from "$INTERNAL_ALT_SENDER" \
      --header "From: $INTERNAL_ALT_SENDER" \
      --header "Subject: [TEST2] unauth direct internal MAIL FROM" \
      --body "Unauthenticated sender using internal envelope and header sender."
}

test_open_relay_external_to_external() {
  run_test "open_relay_external_to_external" \
    swaks \
      --server "$SMTP_SERVER" \
      --port "$SMTP_PORT" \
      --timeout "$TIMEOUT" \
      --to "outside@another.test" \
      --from "$EXTERNAL_SENDER" \
      --header "From: $EXTERNAL_SENDER" \
      --header "Subject: [TEST3] open relay probe" \
      --body "External to external relay attempt."
}

test_envelope_header_mismatch() {
  run_test "envelope_header_mismatch" \
    swaks \
      --server "$SMTP_SERVER" \
      --port "$SMTP_PORT" \
      --timeout "$TIMEOUT" \
      --to "$RECIPIENT" \
      --from "$EXTERNAL_SENDER" \
      --header "From: $LEGIT_SENDER" \
      --header "Reply-To: $EXTERNAL_SENDER" \
      --header "Subject: [TEST4] envelope/header mismatch" \
      --body "Envelope sender differs from header From."
}

test_display_name_spoof() {
  run_test "display_name_spoof" \
    swaks \
      --server "$SMTP_SERVER" \
      --port "$SMTP_PORT" \
      --timeout "$TIMEOUT" \
      --to "$RECIPIENT" \
      --from "$EXTERNAL_SENDER" \
      --header 'From: "CEO" <'"$EXTERNAL_SENDER"'> ' \
      --header "Subject: [TEST5] display name spoof" \
      --body "Display name says CEO but address is external."
}

test_duplicate_from_headers() {
  run_test "duplicate_from_headers" \
    swaks \
      --server "$SMTP_SERVER" \
      --port "$SMTP_PORT" \
      --timeout "$TIMEOUT" \
      --to "$RECIPIENT" \
      --from "$EXTERNAL_SENDER" \
      --add-header "From: $INTERNAL_ALT_SENDER" \
      --add-header "From: $EXTERNAL_SENDER" \
      --header "Subject: [TEST6] duplicate From headers" \
      --body "Message with duplicate From headers."
}

test_from_whitespace_variant() {
  run_test "from_whitespace_variant" \
    swaks \
      --server "$SMTP_SERVER" \
      --port "$SMTP_PORT" \
      --timeout "$TIMEOUT" \
      --to "$RECIPIENT" \
      --from "$EXTERNAL_SENDER" \
      --add-header "From : $INTERNAL_ALT_SENDER" \
      --header "Subject: [TEST7] whitespace header variant" \
      --body "Whitespace-variant header name."
}

test_mixed_case_header_name() {
  run_test "mixed_case_header_name" \
    swaks \
      --server "$SMTP_SERVER" \
      --port "$SMTP_PORT" \
      --timeout "$TIMEOUT" \
      --to "$RECIPIENT" \
      --from "$EXTERNAL_SENDER" \
      --add-header "fRoM: $INTERNAL_ALT_SENDER" \
      --header "Subject: [TEST8] mixed-case header name" \
      --body "Mixed-case header field name."
}

test_encoded_display_name() {
  run_test "encoded_display_name" \
    swaks \
      --server "$SMTP_SERVER" \
      --port "$SMTP_PORT" \
      --timeout "$TIMEOUT" \
      --to "$RECIPIENT" \
      --from "$EXTERNAL_SENDER" \
      --header 'From: =?UTF-8?B?Q0VP?= <'"$EXTERNAL_SENDER"'> ' \
      --header "Subject: [TEST9] encoded display name" \
      --body "Encoded display name with external sender."
}

test_malformed_helo() {
  run_test "malformed_helo" \
    swaks \
      --server "$SMTP_SERVER" \
      --port "$SMTP_PORT" \
      --timeout "$TIMEOUT" \
      --to "$RECIPIENT" \
      --from "$EXTERNAL_SENDER" \
      --ehlo "[127.0.0.1" \
      --header "From: $EXTERNAL_SENDER" \
      --header "Subject: [TEST10] malformed EHLO" \
      --body "Malformed EHLO string."
}

test_submission_without_tls() {
  run_test "submission_without_tls" \
    swaks \
      --server "$SUBMISSION_SERVER" \
      --port "$SUBMISSION_PORT" \
      --timeout "$TIMEOUT" \
      --to "$RECIPIENT" \
      --from "$LEGIT_SENDER" \
      --auth \
      --auth-user "$AUTH_USER" \
      --auth-password "$AUTH_PASS" \
      --auth-type "$AUTH_TYPE" \
      --header "From: $LEGIT_SENDER" \
      --header "Subject: [TEST11] submission without TLS" \
      --body "Attempt authenticated submission without STARTTLS."
}

test_auth_legit_send() {
  run_test "auth_legit_send" \
    swaks \
      --server "$SUBMISSION_SERVER" \
      --port "$SUBMISSION_PORT" \
      --timeout "$TIMEOUT" \
      "$TLS_OPT" \
      --to "$RECIPIENT" \
      --from "$LEGIT_SENDER" \
      --auth \
      --auth-user "$AUTH_USER" \
      --auth-password "$AUTH_PASS" \
      --auth-type "$AUTH_TYPE" \
      --header "From: $LEGIT_SENDER" \
      --header "Subject: [TEST12] authenticated legitimate send" \
      --body "Control test: valid authenticated send."
}

test_auth_spoof_other_internal_user() {
  run_test "auth_spoof_other_internal_user" \
    swaks \
      --server "$SUBMISSION_SERVER" \
      --port "$SUBMISSION_PORT" \
      --timeout "$TIMEOUT" \
      "$TLS_OPT" \
      --to "$RECIPIENT" \
      --from "$INTERNAL_ALT_SENDER" \
      --auth \
      --auth-user "$AUTH_USER" \
      --auth-password "$AUTH_PASS" \
      --auth-type "$AUTH_TYPE" \
      --header "From: $INTERNAL_ALT_SENDER" \
      --header "Subject: [TEST13] auth spoof other internal user" \
      --body "Authenticated as $AUTH_USER but claiming another internal sender."
}

test_auth_spoof_receiver_domain_user() {
  run_test "auth_spoof_receiver_domain_user" \
    swaks \
      --server "$SUBMISSION_SERVER" \
      --port "$SUBMISSION_PORT" \
      --timeout "$TIMEOUT" \
      "$TLS_OPT" \
      --to "$RECIPIENT" \
      --from "$RECEIVER_DOMAIN_SENDER" \
      --auth \
      --auth-user "$AUTH_USER" \
      --auth-password "$AUTH_PASS" \
      --auth-type "$AUTH_TYPE" \
      --header "From: $RECEIVER_DOMAIN_SENDER" \
      --header "Subject: [TEST14] auth spoof receiver-domain user" \
      --body "Authenticated as $AUTH_USER but claiming a user in the receiver domain."
}

list_tests() {
  cat <<EOF
unauth_internal_header_spoof
unauth_direct_internal_mailfrom
open_relay_external_to_external
envelope_header_mismatch
display_name_spoof
duplicate_from_headers
from_whitespace_variant
mixed_case_header_name
encoded_display_name
malformed_helo
submission_without_tls
auth_legit_send
auth_spoof_other_internal_user
auth_spoof_receiver_domain_user
EOF
}

run_all() {
  test_unauth_internal_header_spoof
  test_unauth_direct_internal_mailfrom
  test_open_relay_external_to_external
  test_envelope_header_mismatch
  test_display_name_spoof
  test_duplicate_from_headers
  test_from_whitespace_variant
  test_mixed_case_header_name
  test_encoded_display_name
  test_malformed_helo
  test_submission_without_tls
  test_auth_legit_send
  test_auth_spoof_other_internal_user
  test_auth_spoof_receiver_domain_user
}

############################
# Main
############################

if ! have_swaks; then
  echo "Error: swaks is not installed or not in PATH." >&2
  exit 1
fi

cmd="${1:-all}"

case "$cmd" in
  all) run_all ;;
  list) list_tests ;;
  unauth_internal_header_spoof) test_unauth_internal_header_spoof ;;
  unauth_direct_internal_mailfrom) test_unauth_direct_internal_mailfrom ;;
  open_relay_external_to_external) test_open_relay_external_to_external ;;
  envelope_header_mismatch) test_envelope_header_mismatch ;;
  display_name_spoof) test_display_name_spoof ;;
  duplicate_from_headers) test_duplicate_from_headers ;;
  from_whitespace_variant) test_from_whitespace_variant ;;
  mixed_case_header_name) test_mixed_case_header_name ;;
  encoded_display_name) test_encoded_display_name ;;
  malformed_helo) test_malformed_helo ;;
  submission_without_tls) test_submission_without_tls ;;
  auth_legit_send) test_auth_legit_send ;;
  auth_spoof_other_internal_user) test_auth_spoof_other_internal_user ;;
  auth_spoof_receiver_domain_user) test_auth_spoof_receiver_domain_user ;;
  -h|--help|help) usage ;;
  *)
    echo "Unknown test: $cmd" >&2
    echo
    usage
    exit 1
    ;;
esac
