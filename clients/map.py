from Tkinter import *
from random import randint
from Queue import Queue
from threading import Thread
import socket
import json
import time
import sys
import struct

WIDTH = 800
HEIGHT = 600

def send_message(sock, message):
    message_json = json.dumps(message).encode("utf8")
    message_len = struct.pack('>i', len(message_json))
    sock.send(message_len + message_json)

class Player(object):
    def __init__(self, ground):

        ox, oy = (randint(0, WIDTH), randint(0,HEIGHT))
        fill_color = '#%02X%02X%02X' % (randint(0, 255), randint(0, 255), randint(0, 255))
        self.ground = ground
        self.obj = ground.create_rectangle(ox, oy, ox+4, oy+4, fill=fill_color)

    def move(self, direction):
        dx, dy = self.get_d(direction)
        self.ground.move(self.obj, dx, dy)
        return self.check_wall(direction)

    def get_d(self, direction):
        return {
            't': (0, -1),
            'b': (0, 1),
            'l': (-1, 0),
            'r': (1, 0)
        }[direction]

    def check_wall(self, direction):
        return {
            't': lambda x: x[1] < 0,
            'b': lambda x: x[1]+4 > HEIGHT,
            'l': lambda x: x[0] < 0,
            'r': lambda x: x[0]+4 > WIDTH,
        }[direction](self.ground.coords(self.obj))

class Game(object):
    def __init__(self, in_queue, out_queue):
        self.players = {}
        self.root = Tk()
        self.ground = Canvas(self.root, width=WIDTH, height=HEIGHT)
        self.ground.pack()
        self.in_queue = in_queue
        self.out_queue = out_queue
        self.root.after(33, self.animate)

    def animate(self):
        while not self.in_queue.empty():
            command, args = self.in_queue.get_nowait()

            if command == "s":
                print "added"
                self.add_player(args[0])
                self.out_queue.put_nowait(("ok", args[0]))

            if command == "m":
                is_wall = self.move_player(args[0], args[1])
                if is_wall:
                    print "wall", args[1]
                    self.out_queue.put_nowait(("wall", args[0]))
                else:
                    self.out_queue.put_nowait(("ok", args[0]))
                    
        self.root.after(33, self.animate)
            
    def add_player(self, player_id):
        self.players[player_id] = Player(self.ground)

    def move_player(self, player_id, direction):
        return self.players[player_id].move(direction)

    def check_wall_player(self, player_id, direction):
        return self.players[player_id].check_wall(direction)

def tcp_worker():   
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((TCP_IP, TCP_PORT))
    send_message(s, SUB_MSG)

    reminder = ""

    while True:
        data = s.recv(BUFFER_SIZE)
        if not data:
            break

        reminder = handle_message(reminder + data)

        if reminder is None:
            reminder = ""

        handle_response(s)

    s.close()

def handle_message(data):
    message, reminder = get_message(data)

    if message == "":
        return reminder
    else:
        parse_message(message)
        handle_message(reminder)
    

def parse_message(message):
    msg = json.loads(message)

    if msg["comm"] == "s":
        IN_QUEUE.put_nowait(("s", [msg["id"]]))

    if msg["comm"] == "m":
        IN_QUEUE.put_nowait(("m", [msg["id"], msg["dir"]]))

def handle_response(sock):

    comm, player_id = OUT_QUEUE.get()

    if comm == "ok":
        send_message(sock, {'command': 'send', 'channel': player_id, 'message': {'status': 'ok'}})
    if comm == "wall":
        send_message(sock, {'command': 'send', 'channel': player_id, 'message': {'status': 'wall'}})

    if not OUT_QUEUE.empty():
        handle_response(sock)

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

CHANNEL = 'ch1'

SUB_MSG = {'command': 'subscribe', 'channel': CHANNEL}

IN_QUEUE = Queue()
OUT_QUEUE = Queue()

GAME = Game(IN_QUEUE, OUT_QUEUE)

WORKER = Thread(target=tcp_worker)
WORKER.setDaemon(False)
WORKER.start()

mainloop()



