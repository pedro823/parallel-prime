require 'socket'
require 'thread'

server = TCPServer.open(2000)
loop do
  Thread.start(server.accept) do |client|
    client.puts(Time.now)
    client.close
  end
end
