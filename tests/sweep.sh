#!/usr/bin/env bash
# COSC 407/507 Lab 4 -- how does k2's time depend on the size of a slot? GIVEN.
#
#   bash tests/sweep.sh             at 8 threads (or all your cores, if fewer)
#   THREADS=4 bash tests/sweep.sh   at 4 threads
#
# It rebuilds the GIVEN src/k2.c several times with PAD extra bytes in every
# slot (see slot_t in src/k2.c), so slot[t] and slot[t+1] sit further and
# further apart in memory. Nothing else changes: same loop, same data, same
# answer. Then it times each one (median of REPS runs, default 3) and saves
# results/k2_sweep.csv.
#
# Read the table from the top: where does the time drop, and at what slot
# size does it stop dropping? Compare that number with the cache line size
# this script prints first.

set -u
cd "$(dirname "$0")/.." || exit 2

CC="${CC:-gcc}"
CFLAGS="-std=gnu11 -O2 -g -Wall -Wextra -fopenmp -Iinclude"
REPS="${REPS:-3}"
cores="$(nproc)"
if [ -z "${THREADS:-}" ]; then
    THREADS=8
    [ "$cores" -lt 8 ] && THREADS="$cores"
    [ "$THREADS" -lt 2 ] && THREADS=2
fi

field() { printf '%s\n' "$2" | tr ' ' '\n' | sed -n "s/^$1=//p" | head -1; }
median() { sort -g | awk '{ v[NR] = $1 } END { if (NR % 2) print v[(NR + 1) / 2]; else printf "%.4f\n", (v[NR / 2] + v[NR / 2 + 1]) / 2 }'; }

mkdir -p bin results
line="$(getconf LEVEL1_DCACHE_LINESIZE 2>/dev/null)"
echo "cache line size (getconf LEVEL1_DCACHE_LINESIZE): ${line:-unknown} bytes"
echo "k2 at $THREADS threads on $cores hardware threads, median of $REPS runs each"

$CC $CFLAGS -DPAD=0 -o bin/k2_pad0 src/k2.c src/ref.c -lm || exit 1
natural="$(field slot_bytes "$(bin/k2_pad0 1 64)")"

CSV=results/k2_sweep.csv
echo "slot_bytes,offset,time,vs_given,correct" > "$CSV"
printf '%10s %8s %9s %9s  %s\n' slot_bytes offset time vs_given correct
base=""
for size in 8 16 32 48 64 96 128 256; do
    [ "$size" -lt "$natural" ] && continue
    pad=$(( size - natural ))
    bin="bin/k2_pad$pad"
    [ -x "$bin" ] && [ "$bin" -nt src/k2.c ] || $CC $CFLAGS -DPAD=$pad -o "$bin" src/k2.c src/ref.c -lm || exit 1
    times=""; ok=yes; out=""
    for i in $(seq "$REPS"); do
        out="$(timeout 300 "$bin" "$THREADS" 2>/dev/null)"
        printf '%s' "$out" | grep -q 'correct=yes' || ok=NO
        times+="$(field time "$out")"$'\n'
    done
    t="$(printf '%s' "$times" | grep . | median)"
    off="$(field offset "$out")"
    [ -z "$base" ] && base="$t"
    r="$(awk -v a="$t" -v b="$base" 'BEGIN { printf "%.2f", a / b }')"
    printf '%10s %8s %9s %9s  %s\n' "$size" "$off" "$t" "${r}x" "$ok"
    echo "$size,$off,$t,$r,$ok" >> "$CSV"
done
echo "saved $CSV  (vs_given: this time / the time with the slot as given)"
