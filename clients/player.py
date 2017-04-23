from random import choice
from threading import Thread
import socket
import json
import sys
import struct

DIR = choice(['l', 'r', 't', 'b'])

def wall(direction):
    return {
        't': 'b',
        'b': 't',
        'l': 'r',
        'r': 'l'
    }[direction]

def send_message(sock, command, channel, message):
    message_json = json.dumps({'command': command, 'channel': channel,
                               'message': message}).encode("utf8")
    message_len = struct.pack('>i', len(message_json))
    sock.send(message_len + message_json)

def tcp_worker():   
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((TCP_IP, TCP_PORT))
    send_message(sock, 'subscribe', CHANNEL, '')
    send_message(sock, 'send', TARGET_CHANNEL, {'comm': 's', 'id': CHANNEL})

    reminder = ""

    while True:
        data = sock.recv(BUFFER_SIZE)
        if not data:
            break

        print data

        reminder = handle_message(reminder + data, sock)

        if reminder is None:
            reminder = ""

    sock.close()

def handle_message(data, sock):
    message, reminder = get_message(data)

    if message == "":
        return reminder
    else:
        parse_message(message, sock)
        handle_message(reminder, sock)


def parse_message(message, sock):
    print message
    msg = json.loads(message)

    if msg["status"] == "ok":
        send_message(sock, 'send', TARGET_CHANNEL, {'comm': 'm', 'id': CHANNEL, 'dir': DIR})

    if msg["status"] == "wall":
        global DIR
        DIR = wall(DIR)
        send_message(sock, 'send', TARGET_CHANNEL, {'comm': 'm', 'id': CHANNEL, 'dir': DIR})

def get_message(data):
    if len(data) < 4:
        return ("", data)

    msg_length = struct.unpack('>i', data[:4])[0]

    if msg_length > len(data[4:]):
        return ("", data)
    else:
        return (data[4:4+msg_length], data[4+msg_length:])


TCP_IP = "127.0.0.1"
TCP_PORT = 30001
BUFFER_SIZE = 1024

CHANNEL = sys.argv[1]
TARGET_CHANNEL = "ch1"

SUB_MSG = {'command': 'subscribe', 'channel': CHANNEL}

WORKER = Thread(target=tcp_worker)
WORKER.setDaemon(False)
WORKER.start()
