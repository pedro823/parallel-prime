# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
#

require 'thread'
require './debugger.rb'

# Thread that tries to solve the prime mistery
class Solver
  @prime = 0
  @iteration = 0
  # Initializes a solver.
  # @param {int} lo the lowest number the Solver will need to check.
  # @param {int} hi the highest number the Solver will need to check.
  def initialize(prime_to_check, lo, hi)
    @prime = prime_to_check
    @lo = lo
    @testing = lo
    @hi = hi
    self.solve
    @end = false
  end
  # method that runs in background, solving if the number is prime
  def solve
    @solving = Thread.new do
      (@lo..@hi).each do |i|
        if @stop
          Thread.stop
        end
        @iteration = i
        if @prime % i == 0
          print "Already here\n"
          Thread.current[:proof] = i
          self.signal(i)
          break
        end
      end
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

  def signal(sig)
    @end = true
    if sig == false
      Debugger.debug_print(2, "This section of the code didn't find any divisors!")
    else
      Debugger.debug_print(2, "Found a divisor of", @prime, ":", i)
    end
  end
  # Loads new numbers to calculate.
  def new_load!(new_lo, new_hi)
    s.stop
    @lo = new_lo
    @hi = new_hi
    @end = false
    s.solve
  end
end

## Unit testing
if __FILE__ == $0
  Debugger.set_debug_priority(0)
  s = Solver.new(26898370231697, 2, Math.sqrt(26898370231697).ceil)
  sleep(0.1)
  s.pause
  Debugger.debug_print(3, "Waited 1 sec, current_iteration =", s.current_iteration)
  sleep(0.1)
  Debugger.debug_print(3, "s.end? = ", s.end?)
  Debugger.debug_print(3, "s.paused? =", s.paused?)
  Debugger.debug_print(3, "Waited 1 sec with it paused. current_iteration =", s.current_iteration)
  s.resume
  s.stop
end
