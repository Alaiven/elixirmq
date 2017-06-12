# Elixirmq

**Message queue written in Elixir language**

***Running Elixirmq***

You can run mq by writing in console:

`cd clients/ && mix run --no-halt`

You need to have a Redis database instance running on 127.0.0.1:6379

You can also run mq using an init script:

`python init_mq path_to_redis_server_executable path_to_elixirmq_folder`

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


