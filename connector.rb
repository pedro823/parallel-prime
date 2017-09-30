# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
require 'thread'
require 'socket'
require './messenger.rb'

# Class that administrates connections
class Connector
  attr_reader :connections

  def initialize(port = 7550)
    @connections = {}
    @port = port
    @local_ip = Connector.find_local_ip
    @leader = nil
  end

  def scan
    local = @local_ip.split(".")[0..2].join(".")
    a = []
    (0..255).each do |last_digit|
      a << Thread.new do |this_thread|
        address = local + "." + last_digit.to_s
        m = Messenger.new(address, @port)
        if m.valid?
          @connections[address] = m
        end
      end
    end
    a.each do |thread|
      thread.join
    end
    Debugger.debug_print(2, "Connector: Ended scan")
  end

  def find_leader
    @connections.each do |key, connection|
      Debugger.debug_print(0, "iterating through connection #{connection}")
      if !connection.valid?
        # Removes invalid connection from list
        @connections.reject! { |i| i == connection }
      else
        # pings any connection to know the leader
        connection.ping
        msg = connection.socket.gets.chomp.split(" ")
        if msg.length <= 1
          # Discards malformed message and asks the next person
          Debugger.debug_print(1, "Connection #{connection.ip} sent malformed message: #{message.join(" ")}.")
          next
        end
        if msg[0] == "ANS" and msg[1] == "PING"
          # Found leader
          @leader = msg[2]
          return msg[2]
        end
      end
    end
    raise "Could not find leader"
  end

  def self.find_local_ip
    return Socket.ip_address_list.detect do |ip|
      ip.ipv4_private?
    end.ip_address
  end

  def find_local_ip
    return Connector.find_local_ip
  end

  # Changes host connection to new_host
  def change_host(new_host)
    @connections[:host] = new_host
  end

  def ping_all
    connections.each do |connection|
      connection.ping
    end
  end
end

## Unit testing
if __FILE__ == $0
  Debugger.set_debug_priority(1)
  c = Connector.new(7550)
  puts c.find_local_ip.split('.')[0..2]
  c.scan
  puts c.connections
  puts c.find_leader
end
