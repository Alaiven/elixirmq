from Tkinter import Tk, Canvas, mainloop
from random import randint
from Queue import Queue
from threading import Thread
import socket
import json
import struct

WIDTH = 800
HEIGHT = 600

class Player(object):
    def __init__(self, ground):
        self.posx, self.posy = (randint(0, WIDTH), randint(0, HEIGHT))
        fill_color = '#%02X%02X%02X' % (randint(0, 255), randint(0, 255), randint(0, 255))
        self.ground = ground
        self.obj = ground.create_rectangle(self.posx, self.posy,
                                           self.posx+4, self.posy+4, fill=fill_color)
        self.old_posx = self.posx
        self.old_posy = self.posy

    def move(self, direction):
        distance_x, distance_y = self.get_d(direction)
        self.posx += distance_x
        self.posy += distance_y
        return self.check_wall(direction)

    def place(self):
        distance_x = self.posx - self.old_posx
        distance_y = self.posy - self.old_posy
        self.ground.move(self.obj, distance_x, distance_y)
        self.old_posx = self.posx
        self.old_posy = self.posy

    @staticmethod
    def get_d(direction):
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

    def start(self):
        self.root.after(1, self.place_players)
        worker = Thread(target=self.loop)
        worker.setDaemon(True)
        worker.start()


    def place_players(self):
        for player in self.players.values():
            player.place()
        self.root.after(1, self.place_players)

    def loop(self):
        while True:
            self.animate()

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

    def add_player(self, player_id):
        self.players[player_id] = Player(self.ground)

    def move_player(self, player_id, direction):
        return self.players[player_id].move(direction)

    def check_wall_player(self, player_id, direction):
        return self.players[player_id].check_wall(direction)

class Communicator(object):
    def __init__(self, ip, port, in_queue, out_queue):
        self.in_queue = in_queue
        self.out_queue = out_queue
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.connect((ip, port))

    def start(self):
        worker = Thread(target=self.tcp_worker)
        worker.setDaemon(True)
        worker.start()

    def tcp_worker(self):   
        self.send_message('subscribe', CHANNEL, '')

        reminder = ""

        while True:
            data = self.sock.recv(BUFFER_SIZE)
            if not data:
                break

            reminder = self.handle_message(reminder + data)

            if reminder is None:
                reminder = ""

            self.handle_response()

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

        if msg["comm"] == "s":
            self.in_queue.put_nowait(("s", [msg["id"]]))

        if msg["comm"] == "m":
            self.in_queue.put_nowait(("m", [msg["id"], msg["dir"]]))

    def handle_response(self):

        comm, player_id = self.out_queue.get()

        if comm == "ok":
            self.send_message('send', player_id, {'status': 'ok'})
        if comm == "wall":
            self.send_message('send', player_id, {'status': 'wall'})

        if not self.out_queue.empty():
            self.handle_response()

    @staticmethod
    def get_message(data):
        if len(data) < 4:
            return ("", data)

        msg_length = struct.unpack('>i', data[:4])[0]

        if msg_length > len(data[4:]):
            return ("", data)
        else:
            return (data[4:4+msg_length], data[4+msg_length:])

    def send_message(self, command, channel, message):
        message_json = json.dumps({'command': command, 'channel': channel,
                                   'message': message}).encode("utf8")
        message_len = struct.pack('>i', len(message_json))
        self.sock.send(message_len + message_json)


TCP_IP = "127.0.0.1"
TCP_PORT = 30001
BUFFER_SIZE = 1024

CHANNEL = 'ch1'

SUB_MSG = {'command': 'subscribe', 'channel': CHANNEL}

IN_QUEUE = Queue()
OUT_QUEUE = Queue()

COMMUNICATOR = Communicator(TCP_IP, TCP_PORT, IN_QUEUE, OUT_QUEUE)
COMMUNICATOR.start()

GAME = Game(IN_QUEUE, OUT_QUEUE)
GAME.start()

mainloop()
