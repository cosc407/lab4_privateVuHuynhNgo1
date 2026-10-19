# Lab 4 results — sealed core

Name:  REPLACE THIS LINE
Student number:  REPLACE THIS LINE
Lab section:  REPLACE THIS LINE
Core:  REPLACE THIS LINE — the letter at the top of README.md
Machine:  REPLACE THIS LINE — e.g. "EME 2205 lab PC" or "Codespace"
Cores:  REPLACE THIS LINE — `nproc`, an integer

## Tools and sources

Tools and sources: REPLACE THIS LINE

> Mandatory, even if it says "none". GenAI may explain an idea or a message,
> and nothing else: not the lab's code, not your numbers, not why your
> program is slow, not a line you hand in.

## GenAI log

> Every question you asked a model, word for word, and one line on the
> answer. Asked nothing? Write "none".

REPLACE THIS LINE

## T1 — k1 and Amdahl · 30 marks

> Paste the whole table from `bash tests/scale.sh k1`:

```
```

> f = setup / time from the **serial** row. Amdahl: `1 / (f + (1 - f) / p)`.

| threads | Amdahl's speedup | measured speedup |
|---|---|---|
| 2 | | |
| 4 | | |
| 8 | | |
| 16 | | |

**The gap (12).** At which thread count does your measured speedup fall
clearly below Amdahl's, and what in the machine causes it? Name the
mechanism, and back it with a number from your table and from your machine
(`nproc`, `lscpu`). Compare with what you wrote in P1.

REPLACE THIS LINE

**The digits (4).** Paste the `result=` of your 1-thread and 8-thread runs
(`bin/k1_fix 1`, `bin/k1_fix 8`). Are they identical to the last digit? Why,
or why not — and why does the program still print `correct=yes`?

REPLACE THIS LINE

## T2 — k2, correct and slow · 25 marks

> Paste all of `bash tests/sweep.sh`, then the lines from `bin/k2 4` and
> `bin/k2_fix 4`, then `bash tests/scale.sh k2_fix`:

```
```

**The mechanism (7).** No two threads ever write the same variable. So what
*do* they share, in what unit, and what does the hardware have to do each
time one thread writes its slot? Compare with what you wrote in P2.

REPLACE THIS LINE

**The number (6).** How many bytes per slot did you choose? Give the two
pieces of evidence that it is enough, and say why `offset=0` matters too.

REPLACE THIS LINE

**Ship it (4).** Another way: each thread counts into a local array declared
inside the parallel region, and copies it into `slot[t]` once at the end.
Would that be faster than your fix, and why? Which would you ship, and what
measurement would change your mind?

REPLACE THIS LINE

## T3 — the net loss · 23 marks

> Paste the three tables: `bash tests/scale.sh k3.1`, `k3.2`, `k3.3`.

```
```

**The loser (4).** Which loop is slower with threads than without them?
Give its serial time and its time at 1, 2 and your core count.

REPLACE THIS LINE

**Why it loses (8).** What does each thread do, or wait for, on every
iteration, that the serial version does not? Why do more threads make it
worse rather than better? Compare with P3.

REPLACE THIS LINE

**The one that gains far less (4).** Which loop is it, and what is the one
thing all the threads share that limits it?

REPLACE THIS LINE

**Instead (4).** For the losing loop: what would you change so that a
parallel version beats the serial one? Words are enough, no code. Which
measurement would show that it worked?

REPLACE THIS LINE

## S5 — explain-back · 10 marks

> Three or four sentences, your own words, your own numbers. A team-mate's
> k1 got 3x on 4 threads, and they say: *"so on a 16-core machine it will be
> 12x."* What do you tell them?

REPLACE THIS LINE

## Anything you got stuck on

Optional. One or two lines.
