# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                                 #
#                       EP2 - Redes de computadores e sistemas distribuidos                       #
#                                   Pedro Pereira, 9778794                                        #
#                                   Rafael Gusmão, 9778561                                        #
#                                                                                                 #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require 'thread'
require './debugger.rb'
require './connector.rb'
require './manager.rb'

$TERMINATION_TICK = 5

# Thread that tries to solve the prime mistery
class SolverCreator
  attr_accessor :lo, :hi, :prime, :manager

  def initialize
    @prime = 0
    @iteration = 0
    @finalized = false
  end

  # Initializes the solver.
  # @param {int} lo the lowest number the Solver will need to check.
  # @param {int} hi the highest number the Solver will need to check.
  def setvars(prime_to_check, lo, hi)
    @prime = prime_to_check
    @lo = lo
    @testing = lo
    @hi = hi
    @iteration = "Thread not started"
    self.solve
    @end = false
  end
  # method that runs in background, solving if the number is prime
  def solve
    @solving = Thread.new do
      (@lo..@hi).each do |i|
        if i % 50000 == 0
          sleep(0.001)
        end
        if @stop
          Thread.stop
        end
        @iteration = i
        if @prime % i == 0
          # print "Already here\n"
          Thread.current[:proof] = i
          Debugger.debug_print(1, "signaling solver with #{i}")
          self.signal(i)
          break
        end
      end
      Debugger.debug_print(1, "signaling solver with false")
      self.signal(false)
    end
  end

  def stop
    if @solving and !@end
      @solving.kill
    end
  end

  def pause
    if @solving and !@end
        @stop = true
    end
  end

  def paused?
    return @solving.status == 'sleep'
  end

  def end?
    return @end
  end

  def current_iteration
    return @iteration
  end

  def resume
    if @solving and !@end
        @stop = false
        @solving.run
    end
  end

  def wait_cycle
    @solving.join
  end

  def wait_termination
    # TODO espera ocupada...
    while true
      if @finalized
        break
      end
      sleep($TERMINATION_TICK)
    end
  end

  def signal(sig)
    @end = true
    # Am i my own leader?
    $TRANSFER_MUTEX.synchronize do
      if Connector.leader == Connector.find_local_ip
        Manager.handle_end_internal(@lo, sig)
        new_lo, new_hi = Manager.get_load
        if new_lo == nil
          # No more workload to be done: sleeps
          Debugger.debug_print(4, "get_load returned WAIT. The system will now only wait for others" \
          " to terminate their jobs")
          Solver.pause
          @finalized = true
        else
          new_load!(new_lo, new_hi)
        end
      else
        leader_conn = Connector.connections[Connector.leader]
        $LEADER_SOCKET_MUTEX.synchronize do
          if sig == false
            leader_conn.end("#{@lo} FALSE")
            ans_end = leader_conn.gets.chomp
            Debugger.debug_print(4, "Leader answered END with #{ans_end}")
            new_load = Connector.get_load
            if new_load == nil
              Debugger.debug_print(4, "get_load returned WAIT. The system will now only wait for others" \
              " to terminate their jobs")
              Solver.pause
              @finalized = true
            else
              new_load!(new_load[1].to_i, new_load[2].to_i)
            end
          else
            leader_conn.end("#{@lo} PROOF #{sig}")
          end
        end
      end
    end
  end
  # Loads new numbers to calculate.
  def new_load!(new_lo, new_hi)
    Thread.new do
      Debugger.debug_print(2, "Got new load: #{new_lo} #{new_hi}")
      self.stop
      @lo = new_lo
      @hi = new_hi
      @end = false
      self.solve
    end
  end
end

# Solver is a long lasting instance
Solver = SolverCreator.new

## Unit testing
if __FILE__ == $0
  Debugger.set_debug_priority(0)
  Solver.setvars(26898370231697, 2, Math.sqrt(26898370231697).ceil)
  sleep(0.1)
  Solver.pause
  Debugger.debug_print(3, "Waited 1 sec, current_iteration =", Solver.current_iteration)
  sleep(0.1)
  Debugger.debug_print(3, "s.end? = ", Solver.end?)
  Debugger.debug_print(3, "s.paused? =", Solver.paused?)
  Debugger.debug_print(3, "Waited 1 sec with it paused. current_iteration =", Solver.current_iteration)
  Solver.resume
  Solver.stop
end
