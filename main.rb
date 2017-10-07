# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#

require './connector.rb'
require './handler.rb'
require './messenger.rb'
require './solver.rb'
require './debugger.rb'

# Main Ruby script for running EP2
def print_usage
  puts "Parallel-prime computing"
  puts "peer-to-peer client that computes whether a number is prime or not."
  puts "Usage: ruby #{$0} [NUMBER]"
  puts "NUMBER = number to be checked in peer-to-peer connection"
end

def close_all_connections(connector)
  puts "\nClosing all connections..."
  if !connector.nil?
    connector.connections.each do |key, connection|
      Debugger.status(4, "Shutting down connection with #{key}...")
      connection.close
    end
  end
  puts "\ndone."
end

debug_priority = 4

if ARGV.length > 2
  print_usage
  exit(-1)
else
  # Loads prime
  prime = nil
  ARGV.each do |arg|
    if arg == "--help"
      print_usage
      exit(-1)
    elsif arg[0] == "-"
      debug_priority -= arg.count('d')
    else
      prime = arg.to_i
    end
  end
end

Debugger.set_debug_priority(debug_priority)
connector = Connector.new

# TRAPS ^C into shutting down gracefully
Signal.trap("INT") do
  close_all_connections(connector)
  exit
end

Handler.connector = connector
# connector.scan
leader = connector.find_leader

if leader.nil?
  # No leader yet, sets itself for leader
  if prime.nil?
    raise "Error: No leader found, no prime to calculate."
  else
    connector.leader = Connector.find_local_ip
    min = 0
    max = Math.sqrt(prime).ceil
    solver = Solver.new(prime, min, max)
    Handler.solver = solver
    Debugger.debug_print(4, "Started solving")
    Debugger.debug_print(3, "Solving part from #{min} to #{max}")
    while !solver.end?
      Debugger.status(4, "Solver status = #{solver.current_iteration}    ")
    end
  end
end
