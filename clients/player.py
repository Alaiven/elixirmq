from random import choice
import socket
import json
import sys
import struct

class Player(object):
    def __init__(self, ip, port):
        self.direction = choice(['l', 'r', 't', 'b'])
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.connect((ip, port))

    def start(self):
        self.tcp_worker()

    def wall(self):
        self.direction = {
            't': 'b',
            'b': 't',
            'l': 'r',
            'r': 'l'
        }[self.direction]

    def send_message(self, command, channel, message):
        message_json = json.dumps({'command': command, 'channel': channel,
                                   'message': message}).encode("utf8")
        message_len = struct.pack('>i', len(message_json))
        self.sock.send(message_len + message_json)

    def tcp_worker(self):   
        self.send_message('subscribe', CHANNEL, '')
        self.send_message('send', TARGET_CHANNEL, {'comm': 's', 'id': CHANNEL})

        reminder = ""

        while True:
            data = self.sock.recv(BUFFER_SIZE)
            if not data:
                break

            reminder = self.handle_message(reminder + data)

            if reminder is None:
                reminder = ""

        self.sock.close()

    def handle_message(self, data):
        message, reminder = self.get_message(data)

        if message == "":
            return reminder
        else:
            self.parse_message(message)
            self.handle_message(reminder)


    def parse_message(self, message):
        msg = json.loads(message)

        if msg["status"] == "ok":
            self.send_message('send', TARGET_CHANNEL,
                              {'comm': 'm', 'id': CHANNEL, 'dir': self.direction})

        if msg["status"] == "wall":
            self.wall()
            self.send_message('send', TARGET_CHANNEL,
                              {'comm': 'm', 'id': CHANNEL, 'dir': self.direction})

    @staticmethod
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

PLAYER = Player(TCP_IP, TCP_PORT)
PLAYER.start()
