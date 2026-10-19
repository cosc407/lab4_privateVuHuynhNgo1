#!/usr/bin/env bash
# COSC 407/507 Lab 4 -- a scaling table, measured properly. GIVEN.
#
#   bash tests/scale.sh k1          your fix/k1.c against the serial src/k1.c
#   bash tests/scale.sh k2_fix      your fix/k2.c against the given src/k2.c
#   bash tests/scale.sh k2          the given k2
#   bash tests/scale.sh k3.1        k3 loop 1 (also k3.2, k3.3), against its serial version
#
# What it does, so you do not have to:
#   1. runs the SERIAL baseline -- the code with no OpenMP in it;
#   2. runs the parallel program at 1, 2, 4, 8 and 16 threads;
#   3. runs everything REPS times (default 3) and keeps the MEDIAN time,
#      because one run of anything is not a measurement (Lab 0) -- except a
#      run that takes over 2 seconds, which is run once: a time that long is
#      not noise, and three of them would eat your lab;
#   4. prints speedup = serial time / parallel time, and
#      efficiency = speedup / threads, and saves it all to results/NAME.csv.
#
# Change the thread counts or repetitions without editing anything:
#   THREADS="1 2 3 4" REPS=5 bash tests/scale.sh k1
#
# Every number is time= from the program's own output line. For k1 that is
# setup + kernel: what a user waits for. For k2 and k3 it is the loop alone.

set -u
cd "$(dirname "$0")/.." || exit 2

NAME="${1:-}"
THREADS="${THREADS:-1 2 4 8 16}"
REPS="${REPS:-3}"

case "$NAME" in
    k1)      BASE=(bin/k1 1);          RUN=(bin/k1_fix) ;;
    k2)      BASE=(bin/k2 1);          RUN=(bin/k2) ;;
    k2_fix)  BASE=(bin/k2 1);          RUN=(bin/k2_fix) ;;
    k3.[123]) w="${NAME#k3.}"; BASE=(bin/k3 "$w" 0); RUN=(bin/k3 "$w") ;;
    *)  echo "usage: bash tests/scale.sh k1 | k2 | k2_fix | k3.1 | k3.2 | k3.3" >&2; exit 2 ;;
esac
for b in "${BASE[0]}" "${RUN[0]}"; do
    if [ ! -x "$b" ]; then echo "$b is not built -- run make first" >&2; exit 2; fi
done

field() { printf '%s\n' "$2" | tr ' ' '\n' | sed -n "s/^$1=//p" | head -1; }

# median of the numbers on stdin
median() { sort -g | awk '{ v[NR] = $1 } END { if (NR == 0) print ""; else if (NR % 2) print v[(NR + 1) / 2]; else printf "%.4f\n", (v[NR / 2] + v[NR / 2 + 1]) / 2 }'; }

# measure LABEL CMD... -> prints "time setup kernel ok"
measure() {
    local times="" setups="" kernels="" ok=yes out i
    for i in $(seq "$REPS"); do
        out="$(timeout 300 "$@" 2>/dev/null)"
        if ! printf '%s' "$out" | grep -q 'correct=yes'; then ok=NO; fi
        times+="$(field time "$out")"$'\n'
        setups+="$(field setup "$out")"$'\n'
        kernels+="$(field kernel "$out")"$'\n'
        awk -v t="$(field time "$out")" 'BEGIN { exit !(t > 2.0) }' && break
    done
    printf '%s %s %s %s\n' \
        "$(printf '%s' "$times" | grep . | median)" \
        "$(printf '%s' "$setups" | grep . | median)" \
        "$(printf '%s' "$kernels" | grep . | median)" "$ok"
}

mkdir -p results
CSV="results/$NAME.csv"
echo "threads,time,setup,kernel,speedup,efficiency,correct" > "$CSV"

echo "$NAME on $(nproc) hardware threads, median of $REPS runs each"
printf '%-8s %9s %9s %9s %9s %11s  %s\n' threads time setup kernel speedup efficiency correct
read -r bt bs bk bok <<< "$(measure "${BASE[@]}")"
if [ -z "$bt" ]; then echo "the serial baseline ${BASE[*]} printed no time= -- does it run?" >&2; exit 1; fi
printf '%-8s %9s %9s %9s %9s %11s  %s\n' serial "$bt" "$bs" "$bk" 1.00 - "$bok"
echo "serial,$bt,$bs,$bk,1.00,,$bok" >> "$CSV"

for t in $THREADS; do
    read -r pt ps pk pok <<< "$(measure "${RUN[@]}" "$t")"
    if [ -z "$pt" ]; then
        printf '%-8s did not run, or printed no time=\n' "$t"; continue
    fi
    sp="$(awk -v a="$bt" -v b="$pt" 'BEGIN { if (b > 0) printf "%.2f", a / b; else print "inf" }')"
    ef="$(awk -v s="$sp" -v t="$t" 'BEGIN { printf "%.2f", s / t }')"
    printf '%-8s %9s %9s %9s %9s %11s  %s\n' "$t" "$pt" "$ps" "$pk" "$sp" "$ef" "$pok"
    echo "$t,$pt,$ps,$pk,$sp,$ef,$pok" >> "$CSV"
done
echo "saved $CSV"
