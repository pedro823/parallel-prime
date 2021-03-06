# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                                 #
#                       EP2 - Redes de computadores e sistemas distribuidos                       #
#                                   Pedro Pereira, 9778794                                        #
#                                   Rafael Gusmão,                                                #
#                                                                                                 #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require 'thread'
require 'socket'
require 'timeout'
require './messenger.rb'
require './handler.rb'

# Class that administrates connections
class ConnectorCreator
  attr_reader :connections, :port
  attr_accessor :leader

  def initialize
    @connections = {}
  end

  def setvars(port = 7550)
    @port = port
    @local_ip = self.find_local_ip
    @leader = nil
  end

  def scan
    local = @local_ip.split(".")[0..2].join(".")
    threads = []
    mutex = Mutex.new
    completed = 0
    ('.0'..'.255').each do |last_digit|
      threads << Thread.new do |this_thread|
        address = local + last_digit
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
    threads.each do |thread|
      thread.join
    end
    Debugger.debug_print(2, "Connector: Ended scan")
  end

  def find_leader
    @connections.each do |key, connection|
      if !connection.valid?
        Debugger.debug_print(3, "Connection to #{key} expired")
        @connections.reject! { |conn| conn == connection }
      else
        connection.ping
        msg = connection.gets.chomp.split(" ")
        if msg.length <= 1
          # Discards malformed message and asks the next person
          Debugger.debug_print(1, "Connection #{connection.ip} sent malformed message: #{msg.join(" ")}.")
          next
        end
        if msg[0] == "ANS" and msg[1] == "PING"
          # Found leader
          @leader = msg[2]
          return @leader
        end
      end
    end
    @leader = find_local_ip
    return nil
  end

  def close_connection(ip)
    connection = @connections[ip]
    if connection.nil?
      Debugger.debug_print(4, "Connector.close_connection: Tried to close connection #{ip}" \
                              "but connection does not exist!")
      return
    end
    if connection.valid?
      connection.close
    end
    @connections[ip] = nil
  end

  def serve
    server = TCPServer.open(@port)
    loop do
      Thread.new(server.accept) do |client|
        message = client.gets
        while message.chomp.delete(' ') != 'CLOSE'
          return_msg = Handler.handle_incoming_message(client, message)
          if !return_msg.nil?
            client.puts(return_msg)
          end
          message = client.gets
        end
      end
    end
  end

  def close_all_connections
    @connections.each do |ip, connection|
      if connection.valid?
        connection.close
      end
    end
    @connections = {}
  end

  def add(ip)
    new_messenger = Messenger.new(ip)
    if new_messenger.valid?
      Debugger.debug_print(1, "Adding #{ip} to ip list...")
      @connections[ip] = new_messenger
    else
      return false
    end
    return true
  end

  def find_local_ip
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

  def broadcast(command, message)
    @connections.each do |index, connection|
      if !connection.valid?
        Debugger.debug_print(4, "Connection with #{index} ended.")
        @connections.reject! { |conn| conn == connection }
      else
        connection.send(command, message)
      end
    end
  end

  def get_load
    leader_conn = @connections[@leader]
    leader_conn.receive
    msg = leader_conn.gets.chomp.split(" ")
    if msg[0] == "WAIT"
      return nil
    else
      return msg[2..4]
    end
  end
end

Connector = ConnectorCreator.new

if __FILE__ == $0
  Debugger.set_debug_priority(1)
  Connector.set_vars
  print Connector.find_local_ip
  Connector.scan
  puts "Ended scan"
  puts Connector.connections
  puts Connector.find_leader
end
