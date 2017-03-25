import socket
import json
import time
import sys


TCP_IP = "127.0.0.1"
TCP_PORT = 30001
BUFFER_SIZE = 1024

CHANNEL = sys.argv[1]
TARGET_CHANNEL = sys.argv[2]

SUB_MSG = json.dumps({'command': 'subscribe', 'channel': CHANNEL})

MSG = json.dumps({'command': 'send', 'channel': TARGET_CHANNEL, 'message': {'data': 'from channel:' + CHANNEL}})

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((TCP_IP, TCP_PORT))
s.send(SUB_MSG)

time.sleep(2)

while True:
    s.send(MSG)
    data = s.recv(BUFFER_SIZE)
    if not data:
        break
    print data
    time.sleep(1)
    
s.close()


