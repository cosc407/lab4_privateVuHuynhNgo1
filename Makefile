# COSC 407/507 Lab 4 - the sealed core
#
#   make              build everything into bin/
#   make measure      every measurement the lab asks for, in one go (about 2 min)
#   make test         run the same checks the autograder runs
#   make clean        remove bin/
#
#   bin/k1  bin/k1_fix     the given serial k1, and yours from fix/k1.c
#   bin/k2  bin/k2_fix     the given k2, and yours from fix/k2.c
#   bin/k3                 the three given loops: bin/k3 WHICH THREADS
#
# -fopenmp is not optional: without it every #pragma omp is silently
# ignored and your "parallel" program runs on one thread. -O2 because we
# are timing: an unoptimised build measures the compiler, not the machine.

CC      := gcc
CFLAGS  := -std=gnu11 -O2 -g -Wall -Wextra -fopenmp -Iinclude
LDLIBS  := -lm
HDR     := include/lab4.h

BINS    := bin/k1 bin/k1_fix bin/k2 bin/k2_fix bin/k3

.PHONY: all measure test clean

all: $(BINS)

bin:
	@mkdir -p bin

bin/k1: src/k1.c src/ref.c $(HDR) | bin
	$(CC) $(CFLAGS) -o $@ src/k1.c src/ref.c $(LDLIBS)
bin/k1_fix: fix/k1.c src/ref.c $(HDR) | bin
	$(CC) $(CFLAGS) -o $@ fix/k1.c src/ref.c $(LDLIBS)
bin/k2: src/k2.c src/ref.c $(HDR) | bin
	$(CC) $(CFLAGS) -o $@ src/k2.c src/ref.c $(LDLIBS)
bin/k2_fix: fix/k2.c src/ref.c $(HDR) | bin
	$(CC) $(CFLAGS) -o $@ fix/k2.c src/ref.c $(LDLIBS)
bin/k3: src/k3.c $(HDR) | bin
	$(CC) $(CFLAGS) -o $@ src/k3.c $(LDLIBS)

measure: all
	bash tests/scale.sh k1
	bash tests/sweep.sh
	bash tests/scale.sh k2_fix
	bash tests/scale.sh k3.1
	bash tests/scale.sh k3.2
	bash tests/scale.sh k3.3
	python3 tests/plot.py

test: all
	bash tests/run_tests.sh all

clean:
	rm -rf bin
