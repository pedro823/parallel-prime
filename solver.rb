# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
#

require 'thread'
Thread.abort_on_exception = true

# Thread that tries to solve the prime mistery
class Solver
  @@prime = 0
  # Initializes a solver.
  # @param {int} lo the lowest number the Solver will need to check.
  # @param {int} hi the highest number the Solver will need to check.
  def new(prime_to_check, lo, hi)
    @@prime = prime_to_check
    @lo = lo
    @testing = lo
    @hi = hi
    self.solve
  end
  def solve
    @solving = Thread.new do
      (@lo..@hi).each do |i|
        if @@prime % i
          Thread.current.proof = i
          break
        end
      end
    end
    self.signal
  end
  def stop
    if @solving
      @solving.kill
    end
  end
  def signal
  end
end
