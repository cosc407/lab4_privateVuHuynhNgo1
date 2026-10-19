/* COSC 407/507 Lab 4, core A -- the serial answers, for checking. GIVEN.
 *
 * Do not edit: it is hashed. k1 and k2 call these after their clock has
 * stopped, to decide whether to print correct=yes. They are plain serial
 * copies of the loops in src/k1.c and src/k2.c.
 */
#include <math.h>
#include <stdint.h>

double ref_k1(const double *x, long n)
{
    double sum = 0.0;
    for (long i = 0; i < n; i++)
        sum += sqrt(x[i]) * sin(10.0 * x[i]);
    return sum;
}

void ref_k2(const uint64_t *x, long n, long passes, long out[4])
{
    long once[4] = { 0, 0, 0, 0 };
    for (long i = 0; i < n; i++)
        once[x[i] >> 62]++;
    for (int b = 0; b < 4; b++)
        out[b] = once[b] * passes;
}
