# Prediction — push by 0:20, on its own commit

> Marked on **having predicted**, and on comparing it with what you measured
> in `RESULTS.md` — **not on being right.** A wrong prediction you then explain
> earns full marks. The only program you may run before you push this is
> `bin/k1 1`.

Cores:  12

## P1 — k1 and Amdahl's law

> Paste the line `bin/k1 1` printed:

```
k1 threads=1 n=16777216 setup=0.0770 kernel=0.2727 time=0.3497 result=1698164.8248393852 correct=yes
```

f = setup / time = 0.0770 / 0.3497 ≈ 0.22019, or 22.02%.

> Amdahl's law: `speedup(p) = 1 / (f + (1 - f) / p)`. Put the number it gives
> in the second column. In the third, what you expect to **measure** — a
> number, or "less than Amdahl" / "about the same", with a few words of why.

| threads | Amdahl's speedup | what you expect to measure |
|---|---|---|
| 2 | 1.64 | Slightly less than Amdahl because thread coordination and reduction add overhead. |
| 4 | 2.41 | Slightly less than Amdahl because overhead and competition for shared resources reduce ideal gains. |
| 8 | 3.15 | Less than Amdahl because additional threads share hardware resources and do not provide ideal scaling. |
| 16 | 3.72 | Less than Amdahl; 16 software threads exceed the 12 visible logical CPUs, so extra threads may provide little benefit. |

## P2 — k2

> At 4 threads, will k2 be faster or slower than at 1 thread? If you think
> the slot size matters, at what size in bytes do you expect the time to
> drop, and why that number?

At four threads, I predict the original k2 will be slower at four threads than at one.
Although threads update separate counters, the original 16-byte slots can
share a 64-byte cache line. Repeated writes by different cores can cause
false sharing, with cache-coherence overhead outweighing the benefit of
dividing the work.

I expect a substantial improvement around 64-byte slots, matching the
cache-line size recorded in the public preparation. With the array aligned
to a 64-byte boundary and each slot occupying 64 bytes, different threads'
slots occupy separate cache lines.

## P3 — k3

> Which of the three loops will be the net loss (slower with threads than
> without), which will gain far less than the thread count, and which will
> scale? One line of reason for each.

- **Loop 1 — limited gain:** The scale-and-add loop reads and writes large arrays with little arithmetic per element, so shared memory bandwidth is likely to limit speedup.
- **Loop 2 — net loss:** Each iteration calls the shared `rand()` generator twice; I expect synchronization around its shared state in the lab's C library to cause contention that outweighs parallel benefits.
- **Loop 3 — scales:** The independent `exp` and `cos` calculations provide substantial computational work per iteration, while the reduction combines thread-local sums without serializing every addition.