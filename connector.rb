# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
require 'thread'
require 'socket'
require 'timeout'
require './messenger.rb'

# Class that administrates connections
class Connector
  attr_reader :connections
  attr_accessor :leader

  def initialize(port = 7550)
    @connections = {}
    @port = port
    @local_ip = Connector.find_local_ip
    @leader = nil
  end

  def scan
    local = @local_ip.split(".")[0..2].join(".")
    a = []
    mutex = Mutex.new
    completed = 0
    (0..255).each do |last_digit|
      a << Thread.new do |this_thread|
        address = local + "." + last_digit.to_s
        m = Messenger.new(address, @port)
        mutex.synchronize do
          completed += 1
          Debugger.status(4, "#{completed}/256 ports scanned... (#{completed * 100 / 256}%)")
        end
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
    return nil
  end

  # Closes some client connection.
  # @param {string} ip  The string to close connection to.
  def close_connection(ip)
    connection = @connections[ip]
    if connection.nil?
      Debugger.debug_print(2, "Connector.close_connection: Tried to close Connection #{ip}" +
                              "but connection does not exist!")
      return
    end
    connection.close
    @connections[ip] = nil
  end

  # Adds new connection to @connections
  def add(ip)
    new_messenger = Messenger.new(ip)
    if new_messenger.valid?
      Debugger.debug_print(1, "adding #{ip} to ip list...")
      @connections[ip] = new_messenger
    else
      return false
    end
    return true
  end

  def self.find_local_ip
    begin
      final_ip = nil
      Timeout::timeout(3) do
        final_ip = Socket.ip_address_list.detect do |ip|
          ip.ipv4_private?
        end.ip_address
      end
    rescue
      final_ip = nil
    end
    return final_ip
  end

  def find_local_ip
    return Connector.find_local_ip
  end

  # Changes host connection to new_host
  def change_host(new_host)
    @connections[:host] = new_host
  end

  # Pings every connection
  def ping_all
    @connections.each do |index, connection|
      Debugger.debug_print(1, "Pinging #{index}")
      connection.ping
    end
  end
end

## Unit testing
if __FILE__ == $0
  Debugger.set_debug_priority(0)
  c = Connector.new(7550)
  print c.find_local_ip.split('.')[0..2] * "." + ".*\n"
  c.scan
  puts "Ended scan."
  c.ping_all
  puts c.connections
  puts c.find_leader
end
