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

  def scan
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
            s = m.socket.gets.split(' ')
            if s[0] == "ANS" and s[1] == "PING"
              # Found a service running!
              @connections[address] = m
              @leader = s[3]
            end
          end
        end
      end
    end
    a.each do |i|
      i.join
    end
  end

  def self.find_local_ip
    return Socket.ip_address_list.detect do |ip|
      ip.ipv4_private?
    end.ip_address
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
  c.connections.each do |conn|
    puts conn
  end
end
