# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                                 #
#                       EP2 - Redes de computadores e sistemas distribuidos                       #
#                                   Pedro Pereira, 9778794                                        #
#                                   Rafael Gusmão, 9778561                                        #
#                                                                                                 #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require 'thread'
require 'socket'
require './debugger.rb'
require './connector.rb'
require './manager.rb'
require './solver.rb'

# Class that handles orders from the host
class HandlerCreator
  attr_accessor :solver, :manager, :connector

  def initialize
  end
  # Handles a line coming from the host
  def handle_incoming_message(socket, line)
    Debugger.debug_print(1, "Incoming message from", socket.remote_address.ip_address, ":", line.chomp)
    line = line.chomp.split(" ")
    if line[0] == "PING"
      msg = self.ping(socket, line)
    elsif line[0] == "END"
      msg = self.end(socket, line)
    elsif line[0] == "LOAD"
      msg = self.load(socket, line)
    elsif line[0] == "CLOSE"
      msg = self.close(socket, line)
    elsif line[0] == "HELLO"
      msg = self.hello(socket, line)
    elsif line[0] == "RCVE"
      msg = self.receive(socket, line)
    elsif line[0] == "TRN"
      Solver.pause
      Manager.setvars(Solver.prime, socket.remote_address.ip_address)
      Manager.load_from_leader(socket)
      Solver.resume
    elsif line[0] == "SOLVE"
      msg = self.solve(socket, line)
    elsif line[0] == "LDR"
      msg = self.leader(socket, line)
    else
      msg = self.unknown(socket, line)
    end
    Debugger.debug_print(3, "Handled message from", socket.remote_address.ip_address, ":", msg)
    return msg
  end

  # Responds to HELLO message
  def hello(socket, splitted_line)
    Debugger.debug_print(3, "Handling HELLO message from #{socket.remote_address.ip_address}")
    if Connector.add(socket.remote_address.ip_address)
      Debugger.debug_print(4, "Connections = #{Connector.connections.keys}")
      Debugger.debug_print(4, "New client got into network: #{socket.remote_address.ip_address}")
      return "ANS HELLO HI_THERE"
    end
    return "ANS HELLO INVALID"
  end

  # Responds to RCVE message
  def receive(socket, splitted_line)
    if Connector.leader != Connector.find_local_ip
      return "LDR #{Connector.leader}"
    end
    Debugger.debug_print(3, "Handling receive from #{socket.remote_address.ip_address}")
    new_load = Manager.get_load
    if new_load == nil
      return "WAIT"
    end
    return "ANS RCVE #{Solver.prime} #{new_load[0]} #{new_load[1]}"
  end

  # Responds to LOAD message
  def load(socket, splitted_line)
    if Solver.nil?
      return "ANS LOAD NIL"
    end
    amount = Solver.hi - Solver.current_iteration
    return "ANS LOAD #{amount}"
  end

  # Responds to CLOSE message
  def close(socket, splitted_line)
    ip = socket.remote_address.ip_address
    socket.close
    @connector.connections[ip] = nil
  end

  # Responds to PING message
  def ping(socket, splitted_line)
    leader = Connector.leader
    return "ANS PING #{leader}"
  end

  # Responds to END message
  def end(socket, splitted_line)
    Debugger.debug_print(0, "Handling END message: #{splitted_line * ' '}")
    if Connector.leader != Connector.find_local_ip
      return "ANS END NOT_LEADER"
    end
    Manager.handle_end(socket, splitted_line)
    return "ANS END OK"
  end

  # Responds to LDR message
  def leader(socket, splitted_line)
    Connector.add(splitted_line[1])
    Connector.leader = splitted_line[1]
  end

  # Handles SOLVE message
  def solve(socket, splitted_line)
    if splitted_line[1] == "PRIME"
      handle_solve(false)
    else
      handle_solve(splitted_line[1])
    end
  end

  # Responds to unknown command
  def unknown(socket, splitted_line)
    "ANS UNKNOWN"
  end

  # LAST FUNCTION TO BE CALLED IN THE PROGRAM
  def handle_solve(divisor)
    Connector.close_all_connections
    Solver.stop
    if divisor == false
      Debugger.formal_print("The number #{Solver.prime} was concluded to be PRIME.")
    else
      Debugger.formal_print("Found a divisor of #{Solver.prime}: #{divisor}")
    end
    exit
  end
end

Handler = HandlerCreator.new

## Unit testing
if __FILE__ == $0
  server = TCPServer.open(7550)
  Debugger.set_debug_priority(0)
  Connector.setvars
  Debugger.debug_print(4, "Connector.find_leader = #{Connector.find_leader}")
  Debugger.debug_print(4, "Connector.leader = #{Connector.leader}")
  Handler.connector = Connector
  Handler.solver = Solver
  Solver.setvars(67280421310721, 2, Math.sqrt(67280421310721).ceil)
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
