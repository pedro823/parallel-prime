# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                                 #
#                       EP2 - Redes de computadores e sistemas distribuidos                       #
#                                   Pedro Pereira, 9778794                                        #
#                                   Rafael Gusmão,                                                #
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
    if line[0] == "ANS"
      return self.ans(socket, line)
    elsif line[0] == "PING"
      return self.ping(socket, line)
    elsif line[0] == "END"
      return self.end(socket, line)
    elsif line[0] == "LOAD"
      return self.load(socket, line)
    elsif line[0] == "CLOSE"
      return self.close(socket, line)
    elsif line[0] == "HELLO"
      return self.hello(socket, line)
    elsif line[0] == "RCVE"
      return self.receive(socket, line)
    elsif line[0] == "TRN"
      Manager.setvars(Solver.prime, socket.remote_address.ip_address)
      Manager.load_from_leader(socket)
    elsif line[0] == "SOLVE"
      return self.solve(socket, line)
    end
  end

  # Responds to HELLO message
  def hello(socket, splitted_line)
    Debugger.debug_print(1, "Handling HELLO message from #{socket.remote_address.ip_address}")
    if Connector.add(socket.remote_address.ip_address)
      return "ANS HELLO HI_THERE"
    end
    return "ANS HELLO INVALID"
  end

  # Responds to RCVE message
  def receive(socket, splitted_line)
    if Connector.leader != Connector.find_local_ip
      return "LDR #{Connector.leader}"
    end
    Debugger.debug_print(1, "Handling receive from #{socket.remote_address.ip_address}")
    new_load = Manager.get_load
    if new_load == nil
      return "WAIT"
    else
      
    end
    return "ANS RCVE #{Solver.prime}"
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
    local_ip = Connector.find_local_ip
    return "ANS PING #{local_ip}"
  end

  # Responds to END message
  def end(socket, splitted_line)
    Debugger.debug_print(0, "Handling END message: #{splitted_line * ' '}")
    # TODO END, por enquanto, só está servindo para
    # testar se mandar uma mensagem de split(" ").length == 1
    # não crasha os outros. Implementar ela direito
    return "END"
  end

  # Responds to LDR message
  def leader(socket, splitted_line)
    Connector.add(splitted_line[1])
    Connector.leader = splitted_line[1]
  end

  # Responds to ANS messages
  def ans(socket, splitted_line)
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


  # Handles SOLVE message
  def solve(socket, splitted_line)
    if splitted_line[1] == "PRIME"
      handle_solve(false)
    else
      handle_solve(splitted_line[1])
    end
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
