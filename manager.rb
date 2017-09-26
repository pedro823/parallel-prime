# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
require 'thread'
require 'socket'
require './debugger.rb'
require './connector.rb'

# Class that manages a leader's connection
class Manager
  def initialize(old_leader = nil)
    if old_leader.nil?
      @connections = {}
    else
      @connections = self.transfer
    end
  end
  
end
