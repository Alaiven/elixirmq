import os
import signal
import sys
import time
import subprocess

N_BENCHMARKS = sys.argv[1]
STARTING_AT = sys.argv[2]

def start():
    pl_proc = []

    n_start = int(STARTING_AT)
    n_stop = n_start + (int(N_BENCHMARKS) * 2)

    for i in range(n_start, n_stop, 2):
        pl_proc.append(subprocess.Popen("cd clients && python benchmark.py ch{0} ch{1}"
                                        .format(i, i+1), shell=True))
        print "Benchmark started on channels ch{0} ch{1}". format(i, i+1)
       
    raw_input("Press ENTER to exit!\n")
    print "Exiting..."

    for p in pl_proc:
        os.killpg(os.getpgid(p.pid), signal.SIGTERM)

start()
