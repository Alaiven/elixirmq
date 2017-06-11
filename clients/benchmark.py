from threading import Thread
from time import sleep
import socket
import json
import struct
import sys

CHANNEL = sys.argv[1]
TARGET_CHANNEL = sys.argv[2]

class Benchmark(object):
    def __init__(self, connection_data, channel, target_channel, message):
        self.connection_data = connection_data
        self.channel = channel
        self.target_channel = target_channel
        self.message = message
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.counter = 0
       
    def start(self):
        worker = Thread(target=self.tcp_worker)
        worker.setDaemon(True)
        worker.start()

    def send_message(self, message):
        self.sock.send(message)

    def tcp_worker(self):
        self.sock.connect(self.connection_data)
        self.send_message(self.prepare_message('subscribe', self.channel, ''))
        self.send_message(self.prepare_message('send', self.target_channel, {'data': self.message}))

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
        self.counter += 1
        if self.counter > 10000:
            print "10000 messages:", self.message
            self.counter = 0
        sleep(0.001)
        self.send_message(self.prepare_message('send', self.target_channel, {'data': self.message}))

    @staticmethod
    def get_message(data):
        if len(data) < 4:
            return ("", data)

        msg_length = struct.unpack('>i', data[:4])[0]

        if msg_length > len(data[4:]):
            return ("", data)
        else:
            return (data[4:4+msg_length], data[4+msg_length:])

    @staticmethod
    def prepare_message(command, channel, message):
        message_json = json.dumps({'command': command, 'channel': channel,
                                   'message': message}).encode("utf8")
        message_len = struct.pack('>i', len(message_json))
        return message_len + message_json

CONNECTION_DATA = ("127.0.0.1", 30001)
BUFFER_SIZE = 1024

B1 = Benchmark(CONNECTION_DATA, CHANNEL, TARGET_CHANNEL, "PING")
B2 = Benchmark(CONNECTION_DATA, TARGET_CHANNEL, CHANNEL, "PONG")

B1.start()
B2.start()

print "Benchmark started..."

while True:
    sleep(60)
