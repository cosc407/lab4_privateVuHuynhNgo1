/* COSC 407/507 Lab 4 -- the harness every program in this lab shares. GIVEN.
 *
 * You do not need to read this file to do the lab. It does four boring jobs
 * so that every program measures the same way:
 *
 *   lab4_args()    reads [threads] [n] from the command line and sets the
 *                  OpenMP thread count. threads=0 means "the plain serial
 *                  code, no OpenMP at all" (only bin/k3 uses it).
 *   lab4_fill()    makes the input. Each value is computed FROM THE ONE
 *                  BEFORE IT, so this loop cannot be split between threads:
 *                  it is the serial part of every program, on purpose.
 *   lab4_now()     the clock: omp_get_wtime(), in seconds.
 *   lab4_report()  prints the one line every script reads, e.g.
 *
 *     k1 threads=4 n=8388608 setup=0.0612 kernel=0.0743 time=0.1355 result=... correct=yes
 *
 *                  setup  = the serial part, in seconds
 *                  kernel = the part you can parallelise
 *                  time   = what a user waits for (for k1: setup + kernel)
 */
#ifndef LAB4_H
#define LAB4_H

#include <math.h>
#include <omp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define LAB4_MAX_THREADS 256

typedef struct {
    int  threads;   /* as asked for on the command line; 0 = serial code */
    long n;         /* problem size */
} lab4_args_t;

static inline lab4_args_t lab4_args(int argc, char **argv, long default_n)
{
    lab4_args_t a = { 4, default_n };
    if (argc > 1) a.threads = atoi(argv[1]);
    if (argc > 2) a.n = atol(argv[2]);
    if (a.threads < 0 || a.threads > LAB4_MAX_THREADS || a.n < 1) {
        fprintf(stderr, "usage: %s [threads 0..%d] [n >= 1]\n", argv[0], LAB4_MAX_THREADS);
        exit(2);
    }
    omp_set_num_threads(a.threads > 0 ? a.threads : 1);
    return a;
}

static inline double lab4_now(void) { return omp_get_wtime(); }

/* A linear congruential generator: x[k+1] = A*x[k] + C. Every step needs the
 * step before it -- a loop-carried dependency -- so no number of threads makes
 * this loop faster. That is the serial part Amdahl's law talks about. */
static inline void lab4_fill(uint64_t *x, long n, uint64_t seed)
{
    uint64_t s = seed;
    for (long i = 0; i < n; i++) {
        s = s * 6364136223846793005ULL + 1442695040888963407ULL;
        x[i] = s;
    }
}

/* The same kind of stream, as doubles in [0, 1). */
static inline void lab4_fill_unit(double *x, long n, uint64_t seed)
{
    uint64_t s = seed;
    for (long i = 0; i < n; i++) {
        s = s * 6364136223846793005ULL + 1442695040888963407ULL;
        x[i] = (double)(s >> 11) * 0x1.0p-53;
    }
}

static inline void *lab4_alloc(size_t bytes)
{
    void *p = malloc(bytes);
    if (p == NULL) {
        fprintf(stderr, "out of memory (%zu bytes) -- try a smaller n\n", bytes);
        exit(2);
    }
    return p;
}

static inline void lab4_report(const char *name, lab4_args_t a, double setup,
                               double kernel, double time, double result,
                               int correct)
{
    printf("%s threads=%d n=%ld setup=%.4f kernel=%.4f time=%.4f result=%.17g correct=%s\n",
           name, a.threads, a.n, setup, kernel, time, result, correct ? "yes" : "no");
}

/* Two answers agree if they differ by no more than one part in 10^9. Adding
 * the same numbers in a different order -- which is exactly what threads do --
 * changes the last few digits of a double (class 3: floating-point addition
 * is not associative). It does not change the first nine. */
static inline int lab4_close(double got, double want)
{
    return fabs(got - want) <= 1e-9 * fabs(want) + 1e-12;
}

#endif
