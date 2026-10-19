#!/usr/bin/env python3
"""COSC 407/507 Lab 4 -- draw the scaling curves. GIVEN.

    python3 tests/plot.py

Reads every results/*.csv that tests/scale.sh wrote, and draws

    plots/speedup.png      speedup against threads, with the ideal line
                           (speedup = threads) and, for k1, Amdahl's
                           prediction from your own serial run
    plots/efficiency.png   efficiency = speedup / threads
    plots/k2_sweep.png     k2's time against slot size, if you ran sweep.sh

Speedup is always against the SERIAL code (the "serial" row), so a curve
below 1 is a program that got SLOWER by being parallelised.
"""
import csv
import glob
import os
import sys

try:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
except ImportError:
    sys.exit("matplotlib is missing. In the course container it is installed; "
             "elsewhere: pip install matplotlib (or use the container).")

os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
os.makedirs("plots", exist_ok=True)


def read(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


curves = {}
for path in sorted(glob.glob("results/*.csv")):
    name = os.path.basename(path)[:-4]
    if name == "k2_sweep":
        continue
    rows = read(path)
    serial = [r for r in rows if r["threads"] == "serial"]
    par = [r for r in rows if r["threads"] != "serial" and r["time"]]
    if not serial or not par:
        continue
    curves[name] = (serial[0], par)

if not curves:
    sys.exit("no results/*.csv yet -- run bash tests/scale.sh first")

tmax = max(int(r["threads"]) for _, par in curves.values() for r in par)
ts = list(range(1, tmax + 1))

fig, ax = plt.subplots(figsize=(7, 5))
ax.plot(ts, ts, ":", color="grey", label="ideal: speedup = threads")
for name, (serial, par) in curves.items():
    x = [int(r["threads"]) for r in par]
    y = [float(r["speedup"]) for r in par]
    ax.plot(x, y, "o-", label=name)
    if name == "k1" and serial["setup"] and float(serial["time"]) > 0:
        f = float(serial["setup"]) / float(serial["time"])
        ax.plot(ts, [1 / (f + (1 - f) / p) for p in ts], "--",
                label=f"k1, Amdahl's law with f = {f:.3f}")
ax.axhline(1, color="black", linewidth=0.8)
ax.set_xlabel("threads")
ax.set_ylabel("speedup over the serial code")
cpus = len(os.sched_getaffinity(0)) if hasattr(os, "sched_getaffinity") else os.cpu_count()
ax.set_title(f"Speedup ({cpus} hardware threads available, as nproc says)")
ax.set_xscale("log", base=2)
ax.set_xticks([int(r["threads"]) for r in next(iter(curves.values()))[1]])
ax.get_xaxis().set_major_formatter(matplotlib.ticker.ScalarFormatter())
ax.grid(True, alpha=0.3)
ax.legend(fontsize=8)
fig.tight_layout()
fig.savefig("plots/speedup.png", dpi=120)

fig, ax = plt.subplots(figsize=(7, 5))
for name, (serial, par) in curves.items():
    x = [int(r["threads"]) for r in par]
    y = [float(r["efficiency"]) for r in par]
    ax.plot(x, y, "o-", label=name)
ax.axhline(1, color="grey", linestyle=":", label="ideal: efficiency = 1")
ax.set_xlabel("threads")
ax.set_ylabel("efficiency = speedup / threads")
ax.set_title("Efficiency")
ax.set_xscale("log", base=2)
ax.set_xticks([int(r["threads"]) for r in next(iter(curves.values()))[1]])
ax.get_xaxis().set_major_formatter(matplotlib.ticker.ScalarFormatter())
ax.grid(True, alpha=0.3)
ax.legend(fontsize=8)
fig.tight_layout()
fig.savefig("plots/efficiency.png", dpi=120)
print("wrote plots/speedup.png and plots/efficiency.png")

if os.path.exists("results/k2_sweep.csv"):
    rows = read("results/k2_sweep.csv")
    fig, ax = plt.subplots(figsize=(7, 4))
    ax.plot([int(r["slot_bytes"]) for r in rows], [float(r["time"]) for r in rows], "o-")
    ax.set_xscale("log", base=2)
    ax.set_xticks([int(r["slot_bytes"]) for r in rows])
    ax.get_xaxis().set_major_formatter(matplotlib.ticker.ScalarFormatter())
    ax.set_xlabel("bytes per slot")
    ax.set_ylabel("time (s)")
    ax.set_title("k2: time against slot size")
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    fig.savefig("plots/k2_sweep.png", dpi=120)
    print("wrote plots/k2_sweep.png")
