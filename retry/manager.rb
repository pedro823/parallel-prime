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
require './solver.rb'

$BLOCK_SIZE = 2000000

# Class that manages a leader's connection
class ManagerCreator
  attr_accessor :connector

  def initialize
    @blocks = {}
  end

  def setvars(prime_to_calculate, old_leader = nil)
    Debugger.debug_print(0, "Setting vars for Manager. Depending on prime size, may take a while")
    block = 2
    @hi = Math.sqrt(prime_to_calculate).ceil
    while block < @hi
      @blocks[block.to_s] = false
      block += $BLOCK_SIZE
    end
  end

  def load_from_leader(socket)
    socket.puts("ANS TRN OK")
    Debugger.debug_print(4, "Ready to transfer leadership. ANS TRN OK")
    while message = socket.gets.chomp and message != "FINISH"
      Debugger.debug_print(4, "TRN -- Received #{message}")
      message = message.split(" ")
      block_num = message[1].to_i
      if message[0] == "PROGRESS"
        block_completion = "inprogress"
      else
        block_completion = message[0] == "TRUE" ? true : false
      end
      @blocks[block_num] = block_completion
    end
    Debugger.debug_print(4, "Finished transfer of leadership.")
    broadcast_leader(Connector.find_local_ip)
  end

  def broadcast_leader(ip)
    @connector.broadcast("LDR", ip)
  end

  def transfer_to(messenger)
    messenger.transfer
    message = messenger.gets.chomp.split(" ")
    if message[0] == "ANS" and message[2] == "OK"
      @blocks.each do |block_num, block_completion|
        if block_completion == "inprogress"
          block_completion = "PROGRESS"
        elsif block_completion
          block_completion = "TRUE"
        else
          block_completion = "FALSE"
        end
        messenger.send("NEXT", block_num + " " + block_completion)
      end
      messenger.finish
    end
    Solver.manager = nil
  end

  def get_load
    if @solved
      return nil
    end
    new_load = @blocks.select { |num, value| value == false }.first
    if new_load.nil?
      check_end = @blocks.select { |num, value| value == "inprogress" }.first
      if check_end == nil
        Handler.handle_solve(false)
      end
      return nil
    end
    @blocks[new_load[0]] = "inprogress"
    lo = new_load[0].to_i
    hi = [@hi, lo + $BLOCK_SIZE].min
    return [lo, hi]
  end

  def handle_end_internal(lo, reason)
    Debugger.debug_print(0, "handling internal END message: #{lo} #{reason}")
    if reason == false
      @blocks[lo.to_s] = true
    else
      Debugger.debug_print(3, "This computer found a divisor! #{reason}")
      @solved = true
      Connector.broadcast("SOLVE", reason.to_s)
      Handler.handle_solve(reason)
    end
  end

  def handle_end(socket, splitted_line)
    if splitted_line[1] == "PROOF"
      divisor = splitted_line[2]
      Connector.broadcast("SOLVE", divisor)
      Handler.handle_solve(divisor)
    else

      socket.puts("ANS END OK")
    end
  end
end

Manager = ManagerCreator.new

if __FILE__ == $0
  prime_to_calculate = 2 ** 64 - 1
  Manager.setvars(prime_to_calculate)
  Solver.manager = Manager
  Connector.setvars
  Connector.scan
  Connector.find_leader
  Debugger.debug_print(4, "Connector.leader = #{Connector.leader}")
  Manager.connector = Connector
  puts "Manager created."
  (0..30).each do
    a = Manager.get_load
    if a.nil?
      puts "Nil"
    else
      puts "lo = #{a[0]} hi = #{a[1]}"
    end
  end
  Manager.transfer_to(Connector.connections[Connector.leader])
end
