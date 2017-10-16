#!/usr/bin/env ruby
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                                 #
#                       EP2 - Redes de computadores e sistemas distribuidos                       #
#                                   Pedro Pereira, 9778794                                        #
#                                   Rafael Gusmão, 9778561                                        #
#                                                                                                 #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require 'thread'
require 'socket'
require './handler.rb'
require './manager.rb'
require './debugger.rb'
require './solver.rb'

# Main script for running prime checker
if __FILE__ != $0
  Debugger.formal_print("Error: you cannot import main.rb file. You must run it as a script.")
  exit 1
end

def client_no_prime(port)
  Connector.setvars(port)
  Debugger.debug_print(1, "Started serving at port #{Connector.port}")
  Connector.serve
  Connector.scan
  if Connector.find_leader.nil?
    Debugger.formal_print("Error: No leader found, and no prime specified. The program will now quit.")
    exit
  end
  continue_no_prime
end

def client_prime(port, prime)
  Connector.setvars(port)
  Debugger.debug_print(1, "Started serving at port #{Connector.port}")
  Connector.serve
  Connector.scan
  if !Connector.find_leader.nil?
    Debugger.formal_print("Warning: There is already a leader running. Prime number specified in arguments" \
                          " will be discarded.")
    continue_no_prime
  else
    continue_prime(prime)
  end
end

def continue_no_prime
  leader_conn = Connector.connections[Connector.leader]
  if !leader_conn.nil?
    leader_conn.receive
    new_load_msg = leader_conn.gets.chomp
    Debugger.debug_print(3, "Received first load: #{new_load_msg}")
    msg = new_load_msg.split(" ")
    msg[2..-1].map! { |i| i = i.to_i }
    Solver.setvars(msg[2], msg[3], msg[4])
    Solver.wait_termination
  end
end

def continue_prime(prime)
  # Guarantee: I'm the only one running
  Connector.leader = Connector.find_local_ip
  Manager.setvars(prime)
  Debugger.debug_print(0, "Set vars to manager")
  lo, hi = Manager.get_load
  Debugger.debug_print(0, "Got load: #{lo}\t#{hi}")
  Solver.setvars(prime, lo, hi)
  Debugger.debug_print(0, "Set solver load")
  Solver.wait_termination
end

def close_all_connections
  puts "\nClosing all connections..."
  Connector.connections.each do |key, connection|
    # Debugger.status(4, "Shutting down connection with #{key}...")
    connection.close
  end
end

debug_priority = 5
has_debug_flag = false
prime = nil
port_flag = false
port = 7550
if ARGV.count > 0
  ARGV.each do |arg|
    if port_flag
      port = arg.to_i
      if port < 1024
        Debugger.formal_print("Error: This program is not allowed to run in ports under 1024.")
        exit 1
      end
      port_flag = false
    end
    if arg == "--help"
      Debugger.print_usage
      exit
    elsif arg == "-p"

    elsif arg[0] == "-"
      if has_debug_flag
        Debugger.formal_print("Warning: debug flag set twice. use -ddd instead of -d -d -d.")
      end
      debug_priority -= arg.count("d")
      has_debug_flag = true
    else
      # Assume it is the number
      prime = arg.to_i
      if prime < 2
        Debugger.formal_print("Error: invalid argument #{arg}. Must be a number > 2 to check if is prime")
      end
    end
  end
end

# Shuts down gracefully
Signal.trap("INT") do
  close_all_connections
  exit
end

Debugger.set_debug_priority(debug_priority)
Debugger.debug_print(4, "Debug priority = #{debug_priority}")

if prime.nil?
  client_no_prime(port)
else
  client_prime(port, prime)
end
