# Lab 4 — sealed core A

**100 marks · due at the end of your lab period · GenAI as a tutor only (see the end)**

**Everything you need is on this page.** `PREDICTION.md` and `RESULTS.md`
are the two forms you fill in; they repeat the questions but add no new
instructions. Other sections were given different programs.

## The plan

| time | what you do |
|---|---|
| **0:10–0:20** | Read this page and the three files in `src/`. Run `make` and then **`bin/k1 1`** — the only program you may run before 0:20. Fill in `PREDICTION.md` and **push it on its own commit**. |
| 0:20–0:40 | **Task 1** — make k1 parallel, measure it, compare it with Amdahl's law. |
| 0:40–1:00 | **Task 2** — k2 is correct but slow: find out why with a measurement, then fix it. |
| 1:00–1:12 | **Task 3** — one of k3's three loops gets slower with threads: which, and why? |
| 1:12–1:20 | **S5**, the plots, `make test`, push. |
| **1:20** | **Deadline.** Nothing is accepted after it. |

Stuck for more than 10 minutes on one task? Move to the next one and ask
your TA. A half-finished task with honest numbers earns marks; a blank one
does not.

## Your three programs

| | what it does |
|---|---|
| `k1` | adds up `sqrt(x) sin(10x)` over 2^24 random numbers. **You parallelise it.** |
| `k2` | sorts random values into 4 bands, one slot of 4 `int` counters per thread. Correct, and slow. |
| `k3` | three loops, already parallelised: **1** a scale-and-add over three big arrays · **2** an estimate of pi from random darts · **3** a damped wave summed over 2^23 points. |

`bin/k1`, `bin/k2` and `bin/k3` are built from `src/` — **do not edit `src/`**,
the files are hashed. You work in `fix/k1.c` and `fix/k2.c`, which start as
copies. Every program prints one line ending in `correct=yes` or `correct=no`.

## Task 1 — make k1 parallel, and compare it with Amdahl · 30 marks

1. In `fix/k1.c`, add **one OpenMP line** above the loop in `kernel()` so that
   the loop runs on all threads. Do not change anything else. (Part A,
   section 2, has every line of OpenMP you need.)
2. `make && bin/k1_fix 4` must print `correct=yes`. Try `bin/k1_fix 3 1001` too.
3. `bash tests/scale.sh k1` — it runs the serial program, then yours at 1, 2,
   4, 8 and 16 threads, three times each, and prints a table. Paste the
   table into T1.
4. Fill in the Amdahl table in T1: `f = setup / time` from the **serial** row,
   and `speedup(p) = 1 / (f + (1 - f) / p)`.
5. Answer T1's two questions: where your measurement leaves Amdahl's curve,
   and why; and what happened to the last digits of `result=`.

## Task 2 — k2 is correct and slow · 25 marks

Read the header of `src/k2.c`: every thread counts into its own slot, and
the author is sure that means it scales.

1. `bash tests/sweep.sh` — it rebuilds k2 with bigger and bigger slots and
   times each one. It also prints your cache line size. Paste all of it into T2.
2. In `fix/k2.c`, change **only `slot_t`** so that every slot is exactly one
   cache line and `slot[0]` starts on a cache-line boundary. Keep the `slot[]`
   array and the loop as they are: if moving the data is enough to fix it,
   then the position of the data *was* the problem.
3. `make && bin/k2_fix 4` must print `slot_bytes=64 offset=0` and `correct=yes`.
   Then `bash tests/scale.sh k2_fix`, and paste it.
4. Answer T2's three questions.

## Task 3 — one of these loops is a net loss · 23 marks

Read the header of `src/k3.c`. You change **no code** in this task.

1. `bash tests/scale.sh k3.1`, then `k3.2`, then `k3.3`. Paste all three tables.
   The `serial` row is the loop without OpenMP; every speedup is against it.
2. Answer T3's four questions: which loop loses, why, which one gains far
   less than the thread count, and what you would do instead.

## S5 and handing in · 10 marks

Answer S5 in `RESULTS.md`. Then:

```sh
python3 tests/plot.py           # plots/speedup.png, efficiency.png, k2_sweep.png
make test                       # what the autograder checks
git add -A && git commit -m "Lab 4 core" && git push
```

`make measure` re-runs every measurement and the plots in one go (about two
minutes), if you change a fix late. **Commit `results/` and `plots/`** —
the autograder checks they are there.

## Marks

| | | marks |
|---|---|---|
| **S1** | `PREDICTION.md`, pushed by 0:20 on its own commit. Marked on having predicted, **not on being right**. | 12 |
| **T1** | `fix/k1.c` correct everywhere (6) · table and plots (4) · Amdahl table (4) · the gap (12) · the digits (4) | 30 |
| **T2** | `fix/k2.c` correct (3) · 64 bytes, aligned (3) · the sweep (2) · the mechanism (7) · the number (6) · ship it (4) | 25 |
| **T3** | the three tables (3) · the loser (4) · why it loses (8) · the one that gains less (4) · instead (4) | 23 |
| **S5** | explain-back | 10 |

28 of the 100 are checked by `make test` and `git log`; the other 72 are
what you write, read by a person. **No speedup is ever auto-checked** — the
autograder's machine is not yours. A small effect, honestly measured and
explained, is full marks. `lab mark = automated mark × oral multiplier`,
capped at 100.

## GenAI — as a tutor only

**Allowed:** asking a model to explain an idea or a message — what
`reduction` does, what a cache line is, what Amdahl's law says, what a
compiler warning means. **Not allowed:** showing it the lab's code or your
numbers, asking it why *your* program is slow, or having it write or edit
any code or sentence you hand in. Every question you asked goes in
`RESULTS.md` under `## GenAI log`, word for word, with one line on the
answer. Asked nothing? Write "none". Explaining *why* your program is slow is
the lab.

## The oral test

Five minutes at your machine after the deadline, for the students drawn.
**Oral window 2 starts today**: two questions on this lab, one on Lab 1, 2 or
3. Expect to be asked to run something and read the numbers aloud.
One question you may get: *"Loop 2 prints a different pi every run with threads, and the same one every run without. Why — and is that the reason it is slow?"*
