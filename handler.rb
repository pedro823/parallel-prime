# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
require 'thread'
require 'socket'
require './debugger.rb'
require './connector.rb'
# Class that handles orders from the host
class Handler
  # Handles a line coming from the host
  def self.handle_incoming_message(socket, line)
    Debugger.debug_print(1, "Incoming message from", socket.addr[3], ":", line.chomp)
    line = line.chomp.split(" ")
    line.each do |i|
      puts i
    end
    if line[0] == "ANS"
      return Handler.ans(socket, line)
    elsif line[0] == "PING"
      return Handler.ping(socket, line)
    end
  end

  def self.ping(socket, splitted_line)
    Debugger.debug_print(0, "Im here!")
    local_ip = Connector.find_local_ip
    return "ANS PING #{local_ip}"
  end

  def self.ans(socket, splitted_line)
    if splitted_line[1] == "PING"
      Debugger.debug_print(3, splitted_line * " ")
    end
  end
end

## Unit testing
if __FILE__ == $0
  server = TCPServer.open(7550)
  loop do
    Thread.start(server.accept) do |client|
      a = client.gets
      client.puts(Handler.handle_incoming_message(client, a))
      client.close
    end
  end
end
