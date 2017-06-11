import os
import sys
import subprocess
import time
import signal
from threading import Thread
import redis

REDIS_PATH = sys.argv[1]
MQ_PATH = sys.argv[2]


def start():
    with open("logs/redis_stdout.txt", "wb") as redis_out, \
         open("logs/redis_stderr.txt", "wb") as redis_err, \
         open("logs/mq_stdout.txt", "wb") as mq_out, \
         open("logs/mq_stderr.txt", "wb") as mq_err:

        r_proc = subprocess.Popen(REDIS_PATH,
                                  stdout=redis_out,
                                  stderr=redis_err,
                                  preexec_fn=os.setsid)
        print "STARTED REDIS"
        m_proc = subprocess.Popen("cd "+ MQ_PATH + "&& mix run --no-halt",
                                  shell=True, stdout=mq_out,
                                  stderr=mq_err,
                                  preexec_fn=os.setsid)
        print "STARTED QUEUE"

        msg_worker = Thread(target=msg_work)
        msg_worker.setDaemon(True)
        msg_worker.start()

        raw_input("PRESS ENTER TO EXIT!\n")
        print "EXIT"

        os.killpg(os.getpgid(m_proc.pid), signal.SIGTERM)
        os.killpg(os.getpgid(r_proc.pid), signal.SIGTERM)

def msg_work():
    time.sleep(1)
    messages_count = 0
    redis_client = redis.StrictRedis(host='localhost', port=6379, db=0)

    while True:
        messages_count = redis_client.get('messages:count')
        if messages_count != None:
            print int(messages_count), "[msg/s]"
        else:
            print "0 [msg/s]"
        redis_client.set('messages:count', 0)
        time.sleep(1)

start()
