# Elixirmq

**Message queue written in Elixir language**

***Running Elixirmq***

You can run mq by writing in console:

`cd clients/ && mix run --no-halt`

You need to have a Redis database instance running on 127.0.0.1:6379

You can also run mq using an init script:

`python init_mq path_to_redis_server_executable path_to_elixirmq_folder`

Python script also monitors the number of messages per second

***Using Elixirmq***

Mq handles messages in specific JSON format:

```
{
command : 'command_data',
channel : 'channel_data',
message : { message_data }
}
```

where:

`command_data - name of the command: 'subscribe' or 'send'`

`channel_data - name of the channel you want to subscribe to or send message through`

`message_data - JSON object containing your message. Empty if command == 'subscribe'`

Additionally, you have to prepend your message with an 32bit integer containing the number of bytes in your message.

Mq looks for any subscriber on the given channel and sends them the `message_data` part of initial message prepended with the number of bytes in message.

Mq also stores messages, when no subscriber is present. They will be sent to the first subscriber on the given channel.

Unsubscribing from channels is done when a connection between mq and client is lost.

***Usefull scripts***

There are 2 examples of basic applications using mq:

* Map, invoked by `python init_map.py number_of_players` - map application with players who are sending their desired move and map sending any wall hitting.
* Benchmark, invoked by `python init_benchmark.py number_of_instances starting_index` - benchmark, which, for every `number_of_instances` spawns 2 threads on channels starting from `starting index`.




