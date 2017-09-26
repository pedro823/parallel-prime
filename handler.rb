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
    if line[0] == "ANS"
      return Handler.ans(socket, line)
    elsif line[0] == "PING"
      return Handler.ping(socket, line)
    elsif line[0] == "END"
      return Handler.end(socket, line)
    end
  end

  def self.manager=(value)
    @@manager = value
  end

  def self.manager
    return @@manager
  end

  def self.connector=(value)
    @@connector = value
  end

  def self.connector
    return @@connector
  end

  def self.ping(socket, splitted_line)
    local_ip = Connector.find_local_ip
    return "ANS PING #{local_ip}"
  end

  def self.end(socket, splitted_line)
    Debugger.debug_print(0, "Handling END message: #{splitted_line * ' '}")
    # TODO END, por enquanto, só está servindo para
    # testar se mandar uma mensagem de split(" ").length == 1
    # não crasha os outros. Implementar ela direito
    return "END"
  end

  def self.ans(socket, splitted_line)
    if splitted_line[1] == "PING"
      Debugger.debug_print(3, splitted_line * " ")
    elsif splitted_line[1] == "CLOSE"
      Debugger.debug_print(3, splitted_line * " ")
      # Fuck.
    end
  end
end

## Unit testing
if __FILE__ == $0
  server = TCPServer.open(7550)
  loop do
    Thread.start(server.accept) do |client|
      a = client.gets
      while a.chomp.delete(' ') != "CLOSE"
        client.puts(Handler.handle_incoming_message(client, a))
        a = client.gets
      end
      Debugger.debug_print(0, "Closing connection...")
      client.close
      sleep(2)
      Debugger.debug_print(0, "Closed and slept.")
    end
  end
end
