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
require './solver.rb'

$BLOCK_SIZE = 20000000
$EXPIRE_LEADERSHIP_IN_SECONDS = 40



# Class that manages a leader's connection
class ManagerCreator

  def initialize
    @blocks = {}
  end

  def setvars(prime_to_calculate, old_leader = nil)
    Debugger.debug_print(2, "Setting vars for Manager. Depending on prime size, may take a while")
    block = 2
    @hi = Math.sqrt(prime_to_calculate.to_i).ceil
    while block < @hi
      @blocks[block.to_s] = false
      block += $BLOCK_SIZE
    end
    expire_leadership
  end

  def load_from_leader(socket)
    $TRANSFER_MUTEX.synchronize do
      Debugger.debug_print(0, "manager.load_from_leader locked TRANSFER_MUTEX")
      Debugger.debug_print(4, "I was chosen to be the next leader. Receiving data from \
                              #{socket.remote_address.ip_address}")
      Solver.pause
      $LEADER_SOCKET_MUTEX.synchronize do
        Debugger.debug_print(0, "manager.load_from_leader locked LEADER_SOCKET_MUTEX")
        socket.puts("ANS TRN OK")
        Debugger.debug_print(4, "Ready to transfer leadership. ANS TRN OK")
        message = socket.gets.chomp
        while message.split(" ")[0] != "FINISH"
          Debugger.debug_print(4, "TRN -- Received #{message}")
          message = message.split(" ")
          block_num = message[1]
          if message[2] == "PROGRESS"
            block_completion = "inprogress"
          else
            block_completion = (message[2] == "TRUE" ? true : false)
          end
          @blocks[block_num] = block_completion
          message = socket.gets.chomp
        end
        Connector.leader = Connector.find_local_ip
        Debugger.debug_print(4, "Finished transfer of leadership.")
        broadcast_leader(Connector.find_local_ip)
      end
      Debugger.debug_print(0, "manager.load_from_leader unlocked LEADER_SOCKET_MUTEX")
      Solver.resume
    end
    Debugger.debug_print(0, "manager.load_from_leader unlocked TRANSFER_MUTEX")
  end

  def expire_leadership
    Thread.new do
      sleep($EXPIRE_LEADERSHIP_IN_SECONDS)
      # Removes invalid connections
      Connector.connections.each do |ip, connection|
        if !connection.valid?
          @connections.reject! { |conn| conn == connection }
        end
      end
      # Get random connection
      if Connector.connections.count > 0
        new_leader_ip = Connector.connections.keys.sample
        Debugger.debug_print(4, "Leadership expired, new leader will be #{new_leader_ip}!")
        new_leader = Connector.connections[new_leader_ip]
        transfer_to(new_leader)
      end
    end
  end

  def broadcast_leader(ip)
    Connector.broadcast("LDR", ip)
  end

  def transfer_to(messenger)
    $TRANSFER_MUTEX.synchronize do
      Debugger.debug_print(0, "manager.transfer_to locked TRANSFER MUTEX")
      Solver.pause
      $LEADER_SOCKET_MUTEX.synchronize do
        Debugger.debug_print(0, "manager.transfer_to locked LEADER_SOCKET_MUTEX")
        messenger.transfer
        message = messenger.gets.chomp.split(" ")
        Debugger.debug_print(3)
        while message[0] != "ANS" or message[2] != "OK"
          # Discards any other messages
          message = messenger.gets.chomp.split(" ")
        end
        @blocks.each do |block_num, block_completion|
          if block_completion == "inprogress"
            block_completion = "PROGRESS"
          elsif block_completion
            block_completion = "TRUE"
          else
            block_completion = "FALSE"
          end
          messenger.send("NEXT", block_num.to_s + " " + block_completion)
        end
        messenger.finish
        Connector.leader = messenger.socket.remote_address.ip_address
      end
      Debugger.debug_print(0, "manager.transfer_to unlocked LEADER_SOCKET_MUTEX")
      Solver.resume
    end
    Debugger.debug_print(0, "manager.transfer_to unlocked TRANSFER_MUTEX")
  end

  def get_load
    if @solved
      return nil
    end
    new_load = @blocks.select { |num, value| value == false }.first
    if new_load.nil?
      Debugger.debug_print(0, "get_load -- new_load = nil!")
      check_end = @blocks.select { |num, value| value == "inprogress" }.first
      if check_end.nil?
        Debugger.debug_print(0, "check_end = nil!")
        # All blocks were checked, no one found a divisor
        Connector.broadcast("SOLVE", "PRIME")
        Handler.handle_solve(false)
      else
        # Might as well make him calculate too
        lo = check_end[0].to_i
        hi = [@hi, lo + $BLOCK_SIZE].min
        return [lo, hi]
      end
      return nil
    end
    Debugger.debug_print(0, "Getting new load: new_load = #{new_load}")
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
    if splitted_line[2] == "PROOF"
      divisor = splitted_line[3]
      Connector.broadcast("SOLVE", divisor)
      Handler.handle_solve(divisor)
    else
      calculated_lo = splitted_line[1]
      @blocks[calculated_lo] = true
    end
  end
end

Manager = ManagerCreator.new

if __FILE__ == $0
  prime_to_calculate = 2**61 - 1
  Manager.setvars(prime_to_calculate)
  Solver.manager = Manager
  Connector.setvars
  Connector.scan
  Connector.find_leader
  Debugger.debug_print(4, "Connector.leader = #{Connector.leader}")
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
