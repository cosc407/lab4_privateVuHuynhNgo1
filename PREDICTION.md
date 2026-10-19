# Prediction — push by 0:20, on its own commit

> Marked on **having predicted**, and on comparing it with what you measured
> in `RESULTS.md` — **not on being right.** A wrong prediction you then explain
> earns full marks. The only program you may run before you push this is
> `bin/k1 1`.

Cores:  REPLACE THIS LINE — `nproc`

## P1 — k1 and Amdahl's law

> Paste the line `bin/k1 1` printed:

```
```

f = setup / time =  REPLACE THIS LINE

> Amdahl's law: `speedup(p) = 1 / (f + (1 - f) / p)`. Put the number it gives
> in the second column. In the third, what you expect to **measure** — a
> number, or "less than Amdahl" / "about the same", with a few words of why.

| threads | Amdahl's speedup | what you expect to measure |
|---|---|---|
| 2 | | |
| 4 | | |
| 8 | | |
| 16 | | |

## P2 — k2

> At 4 threads, will k2 be faster or slower than at 1 thread? If you think
> the slot size matters, at what size in bytes do you expect the time to
> drop, and why that number?

REPLACE THIS LINE

## P3 — k3

> Which of the three loops will be the net loss (slower with threads than
> without), which will gain far less than the thread count, and which will
> scale? One line of reason for each.

REPLACE THIS LINE
