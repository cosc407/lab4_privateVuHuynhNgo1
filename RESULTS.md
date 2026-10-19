# Lab 4 results — sealed core

Name:  Vu, Huynh Ngo
Student number:  98651854
Lab section:  L01
Core:  A
Machine:  Docker Container
Cores:  12

## Tools and sources

Tools and sources: AI as a tutor to suggest how to answer with the materials provided in the READINGS section.

> Mandatory, even if it says "none". GenAI may explain an idea or a message,
> and nothing else: not the lab's code, not your numbers, not why your
> program is slow, not a line you hand in.

## GenAI log

> Every question you asked a model, word for word, and one line on the
> answer. Asked nothing? Write "none".

None

## T1 — k1 and Amdahl · 30 marks

> Paste the whole table from `bash tests/scale.sh k1`:

```
threads       time     setup    kernel   speedup  efficiency  correct
serial      0.2966    0.0319    0.2646      1.00           -  yes
1           0.2959    0.0296    0.2664      1.00        1.00  yes
2           0.1675    0.0294    0.1390      1.77        0.89  yes
4           0.1251    0.0309    0.0919      2.37        0.59  yes
8           0.0894    0.0300    0.0594      3.32        0.41  yes
16          0.0836    0.0309    0.0527      3.55        0.22  yes
```

> f = setup / time from the **serial** row. Amdahl: `1 / (f + (1 - f) / p)`.

f = 0.0319 / 0.2966 ≈ 0.10755 (10.76%).

| threads | Amdahl's speedup | measured speedup |
|---|---|---|
| 2 | 1.81 | 1.77 |
| 4 | 3.02 | 2.37 |
| 8 | 4.56 | 3.32 |
| 16 | 6.12 | 3.55 |

**The gap (12).** At which thread count does your measured speedup fall
clearly below Amdahl's, and what in the machine causes it? Name the
mechanism, and back it with a number from your table and from your machine
(`nproc`, `lscpu`). Compare with what you wrote in P1.

At 4 threads, measured speedup is 2.37×, below Amdahl’s 3.02×. Thread overhead and shared hardware resources can limit scaling, though these measurements do not isolate each cost. nproc reports 12 logical CPUs, and lscpu reports 6 cores with 2 threads per core in the virtualized environment. Sixteen threads oversubscribe the visible CPUs. This agrees with P1’s prediction of below-ideal scaling.

**The digits (4).** Paste the `result=` of your 1-thread and 8-thread runs
(`bin/k1_fix 1`, `bin/k1_fix 8`). Are they identical to the last digit? Why,
or why not — and why does the program still print `correct=yes`?

1 thread: result=1698164.8248393852
8 threads: result=1698164.8248395436

The last digits now differ because the parallel reduction changes the addition order, affecting floating-point rounding. Both print correct=yes because the differences remain within the allowed tolerance.

## T2 — k2, correct and slow · 25 marks

> Paste all of `bash tests/sweep.sh`, then the lines from `bin/k2 4` and
> `bin/k2_fix 4`, then `bash tests/scale.sh k2_fix`:

```
cache line size (getconf LEVEL1_DCACHE_LINESIZE): 64 bytes
k2 at 8 threads on 12 hardware threads, median of 3 runs each
slot_bytes   offset      time  vs_given  correct
        16        0    0.2717     1.00x  yes
        32        0    0.1737     0.64x  yes
        48        0    0.1362     0.50x  yes
        64        0    0.0785     0.29x  yes
        96        0    0.0635     0.23x  yes
       128        0    0.0720     0.26x  yes
       256        0    0.0626     0.23x  yes
saved results/k2_sweep.csv  (vs_given: this time / the time with the slot as given)

slot_bytes=16 offset=0  k2 threads=4 n=32768 setup=0.0001 kernel=0.3341 time=0.3341 result=49080000 correct=yes
slot_bytes=64 offset=0  k2 threads=4 n=32768 setup=0.0001 kernel=0.1259 time=0.1259 result=49080000 correct=yes

k2_fix on 12 hardware threads, median of 3 runs each
threads       time     setup    kernel   speedup  efficiency  correct
serial      0.4351    0.0001    0.4351      1.00           -  yes
1           0.4472    0.0001    0.4472      0.97        0.97  yes
2           0.2269    0.0001    0.2269      1.92        0.96  yes
4           0.1188    0.0001    0.1188      3.66        0.92  yes
8           0.0764    0.0001    0.0764      5.70        0.71  yes
16          0.0633    0.0001    0.0633      6.87        0.43  yes
saved results/k2_fix.csv
```

**The mechanism (7).** No two threads ever write the same variable. So what
*do* they share, in what unit, and what does the hardware have to do each
time one thread writes its slot? Compare with what you wrote in P2.

Different counters share a 64-byte cache line, causing ownership transfers and invalidations between cores—false sharing. This supports P2’s mechanism, but the original four-thread run (0.3341 s) was faster than the one-thread baseline (0.4351 s), contrary to my prediction.

**The number (6).** How many bytes per slot did you choose? Give the two
pieces of evidence that it is enough, and say why `offset=0` matters too.

I chose 64-byte slots, matching the measured cache-line size. The sweep improved from 0.2717 s at 16 bytes to 0.0785 s at 64 bytes. offset=0 aligns these slots so neighboring slots do not share cache lines..

**Ship it (4).** Another way: each thread counts into a local array declared
inside the parallel region, and copies it into `slot[t]` once at the end.
Would that be faster than your fix, and why? Which would you ship, and what
measurement would change your mind?

Local counters might be faster because they accumulate locally and copy to the shared array only once, but padded slots already avoid false sharing. I would ship the tested padded version unless repeated, correctness-checked timings showed local counters consistently faster.

## T3 — the net loss · 23 marks

> Paste the three tables: `bash tests/scale.sh k3.1`, `k3.2`, `k3.3`.

```
k3.1 on 12 hardware threads, median of 3 runs each
threads       time     setup    kernel   speedup  efficiency  correct
serial      0.0508    0.0225    0.0508      1.00           -  yes
1           0.0489    0.0189    0.0489      1.04        1.04  yes
2           0.0446    0.0224    0.0446      1.14        0.57  yes
4           0.0421    0.0208    0.0421      1.21        0.30  yes
8           0.0442    0.0193    0.0442      1.15        0.14  yes
16          0.0469    0.0190    0.0469      1.08        0.07  yes

k3.2 on 12 hardware threads, median of 3 runs each
threads       time     setup    kernel   speedup  efficiency  correct
serial      0.2126    0.0000    0.2126      1.00           -  yes
1           0.2122    0.0000    0.2122      1.00        1.00  yes
2           1.4443    0.0000    1.4443      0.15        0.07  yes
4           0.7557    0.0000    0.7557      0.28        0.07  yes
8           1.2588    0.0000    1.2588      0.17        0.02  yes
12          1.3989    0.0000    1.3989      0.15        0.01  yes
16          1.3097    0.0000    1.3097      0.16        0.01  yes

k3.3 on 12 hardware threads, median of 3 runs each
threads       time     setup    kernel   speedup  efficiency  correct
serial      0.1477    0.0152    0.1477      1.00           -  yes
1           0.1522    0.0162    0.1522      0.97        0.97  yes
2           0.0767    0.0168    0.0767      1.93        0.96  yes
4           0.0663    0.0154    0.0663      2.23        0.56  yes
8           0.0442    0.0149    0.0442      3.34        0.42  yes
16          0.0363    0.0169    0.0363      4.07        0.25  yes
```

**The loser (4).** Which loop is slower with threads than without them?
Give its serial time and its time at 1, 2 and your core count.

Loop 2 loses with multiple threads: 0.2126 s serial, 0.2122 s at 1 thread, 1.4443 s at 2, and 1.3989 s at 12. One thread is effectively tied with serial, not slower.

**Why it loses (8).** What does each thread do, or wait for, on every
iteration, that the serial version does not? Why do more threads make it
worse rather than better? Compare with P3.

Each iteration calls the shared rand() generator twice. Synchronization around its shared state creates contention between threads, unlike serial execution. This is consistent with P3’s prediction, although the slowdown is not monotonic as thread count increases.

**The one that gains far less (4).** Which loop is it, and what is the one
thing all the threads share that limits it?

Loop 1 gains little: its best speedup is only 1.21× at 4 threads. Its large-array reads and writes compete for shared memory bandwidth, consistent with the limited scaling.

**Instead (4).** For the losing loop: what would you change so that a
parallel version beats the serial one? Words are enough, no code. Which
measurement would show that it worked?

Use independent per-thread random-generator states with suitable distinct streams, retaining the reduction for hits. Repeated timings below the serial baseline, with correctness and statistical quality preserved, would show improvement.

## S5 — explain-back · 10 marks

> Three or four sentences, your own words, your own numbers. A team-mate's
> k1 got 3x on 4 threads, and they say: *"so on a 16-core machine it will be
> 12x."* What do you tell them?

Getting 3 times speedup with four threads doesn’t mean sixteen cores will give 12 times, because some work stays serial and threads share hardware resources. In my measurements, four threads gave 2.37×, while sixteen gave only 3.55 times. My serial fraction was about 10.76%, which predicts an ideal sixteen-thread speedup of 6.12×, assuming that fraction stays unchanged. We should measure on the new machine rather than multiply the speedup by four.

## Anything you got stuck on

Optional. One or two lines.
