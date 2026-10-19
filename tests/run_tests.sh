#!/usr/bin/env bash
# COSC 407/507 Lab 4, sealed core -- the checks the autograder runs.
#
#   bash tests/run_tests.sh all       everything (default)
#   bash tests/run_tests.sh k1        one group at a time
#
# Groups: given, k1, k2, results, report (the core) or prep (Part A).
#
# IDENTICAL in all four cores. It checks that your programs are CORRECT, that
# your measurements are there, and that your write-up is there. It never
# checks a speedup: the autograder's machine is not yours, and a timing
# threshold would be marking your hardware. Green here is 25 of the 100
# marks; the rest is what you wrote in RESULTS.md, read by a person.
#
# Nothing here hangs: every run has a time limit, and hitting it fails.

set -u
cd "$(dirname "$0")/.." || exit 2

WHICH="${1:-all}"
FAILED=0

pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; FAILED=1; }
info() { printf '  ....  %s\n' "$1"; }

field() { printf '%s\n' "$2" | tr ' ' '\n' | sed -n "s/^$1=//p" | head -1; }

# correct SECS BIN ARGS... : finishes in time and prints correct=yes
correct() {
    local secs=$1; shift
    timeout -k 2 "$secs" "$@" 2>/dev/null | grep -q 'correct=yes'
}

# ------------------------------------------------------------------ given ---
test_given() {
    echo "the given files -- byte for byte as issued"
    local f want have
    for f in src/k1.c src/k2.c src/k3.c src/ref.c include/lab4.h \
             tests/scale.sh tests/sweep.sh; do
        want="$(grep " $f\$" tests/given.sha256 | cut -d' ' -f1)"
        have="$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1)"
        if [ -n "$want" ] && [ "$want" = "$have" ]; then
            pass "$f is unmodified"
        else
            fail "$f has been edited -- 'git checkout $f'; your work goes in fix/"
        fi
    done
}

# --------------------------------------------------------------------- k1 ---
K1_MATRIX=("1" "2" "3" "4" "8" "16" "3 1001" "7 1001" "4 1" "16 5")

check_k1_correct() {   # genuine boolean: 0 only if fully correct, every run
    local args bad=0 i
    [ -x bin/k1_fix ] || return 1
    if cmp -s src/k1.c fix/k1.c || ! grep -q '#[[:space:]]*pragma[[:space:]]\+omp[[:space:]]\+parallel' fix/k1.c; then
        return 1
    fi
    for args in "${K1_MATRIX[@]}"; do
        # shellcheck disable=SC2086
        correct 120 bin/k1_fix $args || bad=1
    done
    for i in 1 2 3; do correct 120 bin/k1_fix 8 || bad=1; done
    [ "$bad" -eq 0 ]
}

test_k1() {
    echo "fix/k1.c -- parallel, and the right answer at every thread count and size"
    local args
    if [ ! -x bin/k1_fix ]; then
        fail "bin/k1_fix was not built -- run make and fix the compile errors"; return
    fi
    if cmp -s src/k1.c fix/k1.c || ! grep -q '#[[:space:]]*pragma[[:space:]]\+omp[[:space:]]\+parallel' fix/k1.c; then
        fail "fix/k1.c has no '#pragma omp parallel' -- it is still the serial program"
        return
    fi
    if check_k1_correct; then
        pass "bin/k1_fix is correct at 1, 2, 3, 4, 8, 16 threads, odd n and tiny n, every time"
    else
        # re-run once more just for the per-case diagnostic lines, now that we
        # know something failed -- avoids doubling cost in the common (pass) case
        for args in "${K1_MATRIX[@]}"; do
            # shellcheck disable=SC2086
            correct 120 bin/k1_fix $args || info "bin/k1_fix $args: wrong answer, or did not finish"
        done
        fail "bin/k1_fix is not correct in every run"
    fi
}

# --------------------------------------------------------------------- k2 ---
K2_MATRIX=("1" "2" "3" "8" "16" "3 1001" "8 5")

check_k2_correct() {   # genuine boolean: correct everywhere, and slot[] kept
    local args bad=0
    [ -x bin/k2_fix ] || return 1
    cmp -s src/k2.c fix/k2.c && return 1
    for args in "${K2_MATRIX[@]}"; do
        # shellcheck disable=SC2086
        correct 120 bin/k2_fix $args || bad=1
    done
    [ "$bad" -eq 0 ] && grep -q 'slot\[' fix/k2.c
}

check_k2_aligned() {   # genuine boolean: slot >= 64 bytes, offset 0
    local out sb off
    [ -x bin/k2_fix ] || return 1
    out="$(timeout 60 bin/k2_fix 2 64 2>/dev/null)"
    sb="$(field slot_bytes "$out")"; off="$(field offset "$out")"
    [ -n "$sb" ] && [ "$sb" -ge 64 ] && [ "$off" = "0" ]
}

test_k2() {
    echo "fix/k2.c -- still correct, and one slot per cache line"
    local args
    if [ ! -x bin/k2_fix ]; then
        fail "bin/k2_fix was not built -- run make and fix the compile errors"; return
    fi
    if cmp -s src/k2.c fix/k2.c; then
        fail "fix/k2.c is still identical to src/k2.c"; return
    fi
    if check_k2_correct; then
        pass "bin/k2_fix is correct at 1, 2, 3, 8, 16 threads and odd n, and keeps the slot array"
    else
        for args in "${K2_MATRIX[@]}"; do
            # shellcheck disable=SC2086
            correct 120 bin/k2_fix $args || info "bin/k2_fix $args: wrong answer, or did not finish"
        done
        fail "bin/k2_fix is not correct in every run, or no longer uses slot[] (the brief says keep it)"
    fi
    if check_k2_aligned; then
        local out sb off
        out="$(timeout 60 bin/k2_fix 2 64 2>/dev/null)"
        sb="$(field slot_bytes "$out")"; off="$(field offset "$out")"
        pass "a slot is $sb bytes and slot[0] starts on a 64-byte boundary"
    else
        local out sb off
        out="$(timeout 60 bin/k2_fix 2 64 2>/dev/null)"
        sb="$(field slot_bytes "$out")"; off="$(field offset "$out")"
        fail "bin/k2_fix prints slot_bytes=${sb:-?} offset=${off:-?} -- want at least 64, and 0"
    fi
}

# ---------------------------------------------------------------- results ---
csv_ok() {     # csv_ok FILE: a serial row plus 1, 2, 4, 8, 16, all correct=yes
    local f=$1 t
    [ -s "$f" ] || return 1
    grep -q '^serial,[0-9.]*,.*,yes$' "$f" || return 1
    for t in 1 2 4 8 16; do
        grep -q "^$t,[0-9.]*,.*,yes\$" "$f" || return 1
    done
}

check_results_k1() {    # genuine boolean: 4-mark row -- csv AND both plots
    csv_ok results/k1.csv && [ -s plots/speedup.png ] && [ -s plots/efficiency.png ]
}

check_results_k2sweep() {   # genuine boolean: 2-mark row
    [ -s results/k2_sweep.csv ] && grep -q '^64,' results/k2_sweep.csv &&
    [ "$(grep -c '^[0-9]' results/k2_sweep.csv)" -ge 4 ]
}

check_results_k3() {   # genuine boolean: 3-mark row -- all three csvs
    local k
    for k in 1 2 3; do
        csv_ok "results/k3.$k.csv" || return 1
    done
    return 0
}

test_results() {
    echo "results/ and plots/ -- the measurements, committed"
    if csv_ok results/k1.csv; then
        pass "results/k1.csv: serial, 1, 2, 4, 8 and 16 threads, all correct"
    else
        fail "results/k1.csv is missing a row or a run was wrong -- bash tests/scale.sh k1"
    fi
    if [ -s plots/speedup.png ] && [ -s plots/efficiency.png ]; then
        pass "plots/speedup.png and plots/efficiency.png are there"
    else
        fail "plots/speedup.png or plots/efficiency.png is missing -- python3 tests/plot.py"
    fi
    if check_results_k2sweep; then
        pass "results/k2_sweep.csv has the sweep, through 64 bytes"
    else
        fail "results/k2_sweep.csv is missing or short -- bash tests/sweep.sh"
    fi
    local k
    if check_results_k3; then
        pass "results/k3.1.csv, k3.2.csv and k3.3.csv are complete"
    else
        for k in 1 2 3; do
            csv_ok "results/k3.$k.csv" || info "results/k3.$k.csv is missing a row -- bash tests/scale.sh k3.$k"
        done
        fail "the k3 results are incomplete"
    fi
}

# ----------------------------------------------------------------- report ---
section() {    # section <file> <heading prefix>: prose only, no fences/quotes/tables
    awk -v h="$2" '
        $0 ~ "^## " h { inside = 1; next }
        /^## /        { inside = 0 }
        inside        { print }
    ' "$1" | awk '
        /^```/    { fence = !fence; next }
        fence     { next }
        /^>/      { next }
        /^\|/     { next }
        /^\*\*/   { next }
        /REPLACE/ { next }
                  { print }
    '
}
fenced() {     # fenced <file> <heading prefix>: only what is inside the fences
    awk -v h="$2" '
        $0 ~ "^## " h { inside = 1; next }
        /^## /        { inside = 0 }
        inside        { print }
    ' "$1" | awk '/^```/ { fence = !fence; next } fence { print }'
}
words() { grep -oE '[A-Za-z]+' | wc -l; }
need_words() {
    if [ "$2" -ge "$1" ]; then pass "$3 is written ($2 words)"
    else fail "$3 is too short ($2 words, expected at least $1)"; fi
}

check_report_prediction() {   # genuine boolean: the 2-mark S1 row -- BOTH sub-checks
    local w n ok=0
    [ -f PREDICTION.md ] || return 1
    grep -q 'REPLACE THIS LINE' PREDICTION.md && ok=1
    n="$(grep -cE '^\| *(2|4|8|16) *\| *[0-9.]+ *\|' PREDICTION.md)"
    w="$(sed '/^>/d;/^\*\*/d;/^#/d;/^|/d' PREDICTION.md | words)"
    { [ "$n" -ge 4 ] && [ "$w" -ge 30 ]; } || ok=1
    [ "$ok" -eq 0 ]
}

check_report_s5() {   # genuine boolean: the 2-mark S5 row
    local w
    [ -f RESULTS.md ] || return 1
    w="$(section RESULTS.md 'S5' | words)"
    [ "$w" -ge 30 ]
}

check_genai_log() {   # GATE -- "no GenAI log -> 0 for the whole lab"
    [ -f RESULTS.md ] || return 1
    section RESULTS.md 'GenAI log' | grep -qv 'REPLACE THIS LINE\|^[[:space:]]*$'
}

test_report() {
    echo "PREDICTION.md and RESULTS.md"
    local w n
    if [ ! -f PREDICTION.md ]; then
        fail "PREDICTION.md is missing -- it is due at 0:20"
    else
        if grep -q 'REPLACE THIS LINE' PREDICTION.md; then
            fail "PREDICTION.md still contains a 'REPLACE THIS LINE' placeholder"
        else
            pass "no placeholders left in PREDICTION.md"
        fi
        n="$(grep -cE '^\| *(2|4|8|16) *\| *[0-9.]+ *\|' PREDICTION.md)"
        w="$(sed '/^>/d;/^\*\*/d;/^#/d;/^|/d' PREDICTION.md | words)"
        if [ "$n" -ge 4 ] && [ "$w" -ge 30 ]; then
            pass "the Amdahl table has four numbers and P2-P3 are written"
        else
            fail "PREDICTION.md: a number in each row of the Amdahl table, and P2 and P3 written"
        fi
    fi

    if [ ! -f RESULTS.md ]; then
        fail "RESULTS.md is missing"; return
    fi
    if grep -q 'REPLACE THIS LINE' RESULTS.md; then
        fail "RESULTS.md still contains a 'REPLACE THIS LINE' placeholder"
    else
        pass "no placeholders left in RESULTS.md"
    fi
    local disc
    disc="$(sed -n 's/^[Tt]ools and sources:[[:space:]]*//p' RESULTS.md | head -1)"
    if [ -n "$disc" ]; then
        pass "the tools-and-sources disclosure is filled in"
    else
        fail "RESULTS.md must state your tools and sources, or say explicitly you used none"
    fi
    if check_genai_log; then
        pass "the GenAI log is filled in (even if it says 'none')"
    else
        fail "RESULTS.md: the GenAI log is empty -- write every question you asked, or 'none'"
    fi
    if grep -qiE '^[[:space:]]*[Cc]ores:[[:space:]]*[0-9]+' RESULTS.md; then
        pass "the machine's core count is recorded"
    else
        fail "RESULTS.md must record the machine's core count"
    fi
    if [ "$(fenced RESULTS.md 'T1' | grep -cE '^(serial|1|2|4|8|16) ')" -ge 6 ]; then
        pass "T1 pastes the k1 scaling table"
    else
        fail "T1 must paste the table from bash tests/scale.sh k1"
    fi
    w="$(section RESULTS.md 'T1' | words)"; need_words 80 "$w" "T1"
    if [ "$(fenced RESULTS.md 'T2' | grep -cE '^ *[0-9]+ +[0-9]+ +[0-9.]+')" -ge 4 ]; then
        pass "T2 pastes the k2 sweep"
    else
        fail "T2 must paste the table from bash tests/sweep.sh"
    fi
    w="$(section RESULTS.md 'T2' | words)"; need_words 80 "$w" "T2"
    if [ "$(fenced RESULTS.md 'T3' | grep -c '^serial ')" -ge 3 ]; then
        pass "T3 pastes the three k3 tables"
    else
        fail "T3 must paste all three tables from bash tests/scale.sh k3.1 / k3.2 / k3.3"
    fi
    w="$(section RESULTS.md 'T3' | words)"; need_words 80 "$w" "T3"
    w="$(section RESULTS.md 'S5' | words)"; need_words 30 "$w" "S5"
}

test_prep() {   # Part A only
    echo "PREP.md -- what your TA checks at 0:10"
    if [ ! -f PREP.md ]; then fail "PREP.md is missing"; return; fi
    if grep -q 'REPLACE THIS LINE' PREP.md; then
        fail "PREP.md still contains a 'REPLACE THIS LINE' placeholder"
    else
        pass "no placeholders left in PREP.md"
    fi
    if grep -qiE '^[[:space:]]*[Cc]ores:[[:space:]]*[0-9]+' PREP.md; then
        pass "the machine's core count is recorded"
    else
        fail "PREP.md must record the machine's core count"
    fi
    if [ "$(grep -c '^serial ' PREP.md)" -ge 4 ]; then
        pass "PREP.md pastes the four scaling tables (k1, k3.1, k3.2, k3.3)"
    else
        fail "PREP.md must paste the tables from scale.sh: k1, k3.1, k3.2 and k3.3"
    fi
}

# ------------------------------------------------------------------ score ---
SCORE=0
row() {   # row <max marks> <label> <command...>
    # Stdout is left visible (not silenced) so a check with real internal
    # diagnostics prints which specific sub-condition failed, not just an
    # opaque 0/N for the whole row. Simple boolean-only checks print nothing
    # extra either way, so this is safe for every row.
    local max="$1" label="$2"; shift 2
    if "$@" 2>/dev/null; then
        printf '  %2s / %-3s %s\n' "$max" "$max" "$label"
        SCORE=$(awk -v a="$SCORE" -v b="$max" 'BEGIN{printf "%g", a+b}')
    else
        printf '  %2s / %-3s %s\n' "0" "$max" "$label"
    fi
}

test_score() {
    echo "Script-checked rows (out of 25)"
    row 2  "S1: PREDICTION.md present, no placeholders, Amdahl table + P2-P3" check_report_prediction
    row 6  "T1: fix/k1.c correct, every thread count, odd/tiny n, repeatedly" check_k1_correct
    row 4  "T1: results/k1.csv complete; plots/speedup.png, efficiency.png"  check_results_k1
    row 3  "T2: fix/k2.c correct, slot[] kept"                              check_k2_correct
    row 3  "T2: slot >= 64 bytes, slot[0] at offset 0"                      check_k2_aligned
    row 2  "T2: results/k2_sweep.csv present"                               check_results_k2sweep
    row 3  "T3: results/k3.1.csv, k3.2.csv, k3.3.csv complete"              check_results_k3
    row 2  "S5: present, own words (30+ words)"                            check_report_s5
    echo
    echo "Script-checked score: $SCORE / 25"
    echo "This is not the lab mark -- 72 of the 100 marks (the Amdahl"
    echo "reconciliation, the gap, the mechanism, the loser and why, S5's"
    echo "12-mark answer) are person-judged, same as every lab. The 3-mark"
    echo "'pushed before any change to fix/' row is checked from git log,"
    echo "not from this script."
    echo
    if [ ! -f RESULTS.md ]; then
        fail "RESULTS.md is missing"
    else
        if grep -q 'REPLACE THIS LINE' RESULTS.md; then
            fail "RESULTS.md still contains a 'REPLACE THIS LINE' placeholder"
        else
            pass "no placeholders left in RESULTS.md"
        fi
        local disc
        disc="$(sed -n 's/^[Tt]ools and sources:[[:space:]]*//p' RESULTS.md | head -1)"
        if [ -n "$disc" ]; then
            pass "the tools-and-sources disclosure is filled in"
        else
            fail "RESULTS.md must state your tools and sources, or say explicitly you used none"
        fi
        if check_genai_log; then
            pass "the GenAI log is filled in (even if it says 'none')"
        else
            fail "RESULTS.md: the GenAI log is empty -- write every question you asked, or 'none'"
        fi
    fi
}

# ---------------------------------------------------------------------------
[ "$WHICH" = all ] && [ -f PREP.md ] && WHICH=all-prep
case "$WHICH" in
    prep)    test_prep ;;
    all-prep) test_given; echo; test_k1; echo; test_k2; echo
             test_results; echo; test_prep ;;
    given)   test_given ;;
    k1)      test_k1 ;;
    k2)      test_k2 ;;
    results) test_results ;;
    report)  test_report ;;
    score)   test_score ;;
    all)     test_given; echo; test_k1; echo; test_k2; echo
             test_results; echo; test_report ;;
    *)       echo "usage: $0 [all|given|k1|k2|results|report|score|prep]" >&2; exit 2 ;;
esac

echo
if [ "$FAILED" -eq 0 ]; then echo "all checks passed for: $WHICH"
else echo "there are failures above for: $WHICH"; fi
exit "$FAILED"
