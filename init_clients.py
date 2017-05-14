import os
import signal
import sys
import time
import subprocess

N_CLIENTS = sys.argv[1]

def start():
    map_proc = subprocess.Popen("cd clients && python map.py", shell=True)
    print "STARTED MAP"

    pl_proc = []

    for i in range(2, int(N_CLIENTS) + 2):
        pl_proc.append(subprocess.Popen("cd clients && python player.py ch" + str(i), shell=True))
        print "STARTED PLAYER ON CHANNEL", "CH" + str(i)
       
    raw_input("PRESS ENTER TO EXIT!\n")
    print "EXIT"

    os.killpg(os.getpgid(map_proc.pid), signal.SIGTERM) 

    for p in pl_proc:
        os.killpg(os.getpgid(p.pid), signal.SIGTERM)

start()
