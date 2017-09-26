# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
require 'thread'
require 'socket'
require './messenger.rb'

# Class that administrates connections
class Connector
  def initialize(port = 7550)
    @connections = {}
    @port = port
    @local_ip = Connector.find_local_ip
    @leader = nil
  end

  def find_leader
    local = @local_ip.split(".")[0..2].join(".")
    a = []
    (0...16).each do |i| #TODO melhorar isso. bastante.
      # Starts 16 new threads searching for services at the port
      a << Thread.new do |this_thread|
        (i * 16...(i + 1) * 16).each do |last_digit|
          address = local + "." + last_digit.to_s
          m = Messenger.new(address, @port)
          # Is there a valid service running?
          if m.valid?
            # Try pinging it and see the response
            m.ping
            s = m.socket.gets.chomp.split(' ')
            if s[0] == "ANS" and s[1] == "PING"
              # Found a service running!
              Debugger.debug_print(1, "FOUND SERVICE AT #{address}")
              @connections[address] = m
              @leader = s[2]
              Debugger.debug_print(1, "LEADER IS NOW #{s[2]}")
            end
          end
          if !@leader.nil?
            break
          end
        end
      end
    end
    a.each do |i|
      i.join
    end
  end

  # Asks the leader for all the connections it has.
  # MUST HAVE LEADER DEFINED.
  def scan
    if @leader.nil?
      raise "Leader is nil: Always find_leader first."
    end
    # Is the leader connection any good?
    lead_conn = @connections[@leader]
    if lead_conn.nil?
    end
  end

  def self.find_local_ip
    return Socket.ip_address_list.detect do |ip|
      ip.ipv4_private?
    end.ip_address
  end

  def find_local_ip
    return Connector.find_local_ip
  end

  def connections
    return @connections
  end
  # Changes host connection to new_host
  def change_host(new_host)
    @connections[:host] = new_host
  end

  def ping_all
    connections.each do |connection|
      connection.ping()
    end
  end
end

## Unit testing
if __FILE__ == $0
  Debugger.set_debug_priority(1)
  c = Connector.new(7550)
  puts c.find_local_ip.split('.')[0..2]
  c.find_leader
  puts c.connections
end
