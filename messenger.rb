# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#

require './debugger.rb'
require './handler.rb'
require 'thread'
require 'socket'

# Class responsible for all the messaging between systems
# Each connection to another computer has a different messenger
class Messenger
  attr_reader :socket
  attr_reader :ip

  @@commands = {
    :receive  => "RCVE",
    :load     => "LOAD",
    :split    => "SPLIT",
    :end      => "END",
    :ping     => "PING",
    :capacity => "CAP",
    :transfer => "TRN",
    :answer   => "ANS",
    :close    => "CLOSE"
  }
  # Creates a new messenger
  # @param ip {URI} The URI of the other computer
  # @param port {integer} the port to connect to (Default: 7550)
  def initialize(ip, port = 7550)
    @answer_queue = []
    @ip = ip
    @port = port
    begin
      @socket = TCPSocket.new(ip, port)
      @valid = true
      Debugger.debug_print(1, "Found address #{ip}!")
    rescue
      Debugger.debug_print(0, "IP address has connections closed: #{ip}")
      @valid = false
    end
  end

  def create_read_thread
    @end = false
    @read_thread = Thread.new do
      while line = @socket.gets and !@end
        Debugger.debug_print(0, "Message from", ip, ":\t", line)
        Handler.handle_incoming_message(@socket, line, @answer_queue)
      end
      if !@end
        # Connections stopped abruptly! Try pinging leader

      end
    end
  end

  def end_read_thread
    if @read_thread.status
      @end = true
      self.close
    end
    @read_thread.join
  end

  def send(command, message)
    final_message = command + ' ' + message
    @socket.puts(final_message)
  end

  def valid?
    return @valid
  end

  # So that it is able to print a
  def to_ary
    return ["Messenger valid = #{@valid} | ip = #{@socket.remote_address.ip_address} | port = #{@port}"]
  end

  def method_missing(method, *args)
    message = ''
    if @@commands[method] == nil
      raise "No such method: #{method}"
    end
    if !args.nil?
      args.each do |i|
        message << i.to_s.chomp.upcase + ' '
      end
    end
    self.send(@@commands[method], message)
  end
end

# Handler that, instead of sending the message to the handler,
# receives a continuation function and passes line received to it
# instead
class ComplexMessenger < Messenger
  # User is able to read and write to lambda_set
  attr_accessor :lambda_set

  # @@commands = {
  #   :receive  => "RCVE",
  #   :load     => "LOAD",
  #   :split    => "SPLIT",
  #   :end      => "END",
  #   :ping     => "PING",
  #   :capacity => "CAP",
  #   :transfer => "TRN",
  #   :answer   => "ANS"
  # }
  # Creates a new SimpleMessenger
  # @param ip {String}       The IP of the connection
  # @param lambda_set {Hash} The set of functions to be handled
  # @param port {Integer}    The port of the connection
  def initialize(ip, lambda_set, port = 7550)
    @ip = ip
    @lambda_set = {}
    begin
      @socket = TCPSocket.new(ip, port)
      @valid = true
      Debugger.debug_print(1, "Found address #{ip}!")
      @@commands.each do |key, value|
        # Overwrites the functions to be handled, defaults to handler if not overwriten
        @lambda_set[value] = lambda_set[value] || -> input { Handler.handle_incoming_message(@socket, input) }
      end
    rescue
      Debugger.debug_print(0, "IP address has connections closed: #{ip}")
      @valid = false
    end
  end

  def create_read_thread
    @read_thread = Thread.new do
      while line = @socket.gets
        Debugger.debug_print(0, "Message from", ip, ":\t", line)
        splitted_line = line.chomp.split(" ")
        if splitted_line.length < 2 # and splitted_line[0] == "ANS"
          Debugger.debug_print(0, "DISCARDED MESSAGE -- MALFORMED")
          next # Malformed message, discards
        end
        command = line.chomp.split(" ")[1]
        # Runs lambda function from lambda set
        @lambda_set[command].(line)
      end
    end
  end
end

if __FILE__ == $0
  a = Messenger.new('localhost', 7550)
  puts a
  if a.valid?
    a.end('proof', '23')
  end
  lambda_set = {
    "PING" => -> input {
      puts "Received PING inside lambda_set: #{input}"
    }
  }
  b = ComplexMessenger.new("localhost", lambda_set)
  puts b
  if b.valid?
    b.create_read_thread
    b.ping
    b.end_read_thread
  end
end
