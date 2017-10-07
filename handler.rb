# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
require 'thread'
require 'socket'
require './debugger.rb'
require './connector.rb'
require './solver.rb'
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
    elsif line[0] == "LOAD"
      return Handler.load(socket, line)
    elsif line[0] == "CLOSE"
      return Handler.close(socket, line)
    elsif line[0] == "HELLO"
      return Handler.hello(socket, line)
    end
  end

  # Sets and gets solver for the handler
  def self.solver=(value)
    @@solver = value
  end

  def self.solver
    return @@solver
  end

  # Sets and gets solver for the Handler
  def self.manager=(value)
    @@manager = value
  end

  def self.manager
    return @@manager
  end

  # Sets and gets connector for the Handler
  def self.connector=(value)
    @@connector = value
  end

  def self.connector
    return @@connector
  end

  # Responds to HELLO message
  def self.hello(socket, splitted_line)
    Debugger.debug_print(1, "Handling HELLO message from #{socket.addr[3]}")
    if @@connector.add(socket.addr[3])
      return "ANS HELLO HI_THERE"
    end
    return "ANS HELLO INVALID"
  end

  # Responds to LOAD message
  def self.load(socket, splitted_line)
    if @@solver.nil?
      return "ANS LOAD NIL"
    end
    amount = @@solver.hi - @@solver.current_iteration
    return "ANS LOAD #{amount}"
  end

  # Responds to CLOSE message
  def self.close(socket, splitted_line)
    ip = socket.addr[3]
    socket.close
    @@connector.connections[ip] = nil
  end

  # Responds to PING message
  def self.ping(socket, splitted_line)
    local_ip = Connector.find_local_ip
    return "ANS PING #{local_ip}"
  end

  # Responds to END message
  def self.end(socket, splitted_line)
    Debugger.debug_print(0, "Handling END message: #{splitted_line * ' '}")
    # TODO END, por enquanto, só está servindo para
    # testar se mandar uma mensagem de split(" ").length == 1
    # não crasha os outros. Implementar ela direito
    return "END"
  end

  # Responds to ANS messages
  def self.ans(socket, splitted_line)
    if splitted_line[1] == "PING"
      Debugger.debug_print(3, splitted_line * " ")
    elsif splitted_line[1] == "HELLO"
      if splitted_line.length < 3
        # Discards message
        return
      end
      if splitted_line[2] != "HI_THERE"

      end

    elsif splitted_line[1] == "CLOSE"
      Debugger.debug_print(3, splitted_line * " ")
      # Fuck.
    end
  end
end

## Unit testing
if __FILE__ == $0
  server = TCPServer.open(7550)
  Handler.connector = Connector.new
  Handler.solver = Solver.new(67280421310721, 2, Math.sqrt(67280421310721).ceil)
  sleep(0.1)
  Handler.solver.pause
  loop do
    Debugger.debug_print(0, "Solver status: #{Handler.solver.current_iteration}")
    Thread.start(server.accept) do |client|
      a = client.gets
      while a.chomp.delete(' ') != "CLOSE"
        msg = Handler.handle_incoming_message(client, a)
        if !msg.nil?
          client.puts(msg)
        end
        a = client.gets
      end
      Debugger.debug_print(0, "Closing connection...")
      client.close
      sleep(2)
      Debugger.debug_print(0, "Closed and slept.")
    end
  end
end
