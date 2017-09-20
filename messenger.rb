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
  @@commands = {
    :receive  => "RCVE",
    :load     => "LOAD",
    :split    => "SPLIT",
    :end      => "END",
    :ping     => "PING",
    :capacity => "CAP",
    :transfer => "TRN",
    :answer   => "ANS"
  }
  # Creates a new messenger
  # @param ip {URI} The URI of the other computer
  # @param port {integer} the port to connect to (Default: 7550)
  def initialize(ip, port = 7550)
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
    @read_thread = Thread.new do
      while line = @socket.gets
        Debugger.debug_print(0, "Message from", ip, ":\t", line)
        Handler.handle_incoming_message(@socket, line)
      end
    end
  end

  def send(command, message)
    final_message = command + ' ' + message
    @socket.puts(final_message)
  end

  def valid?
    return @valid
  end

  def socket
    return @socket
  end

  def method_missing(method, *args)
    message = ''
    if !args.nil?
      args.each do |i|
        puts i
        message << i.to_s.upcase + ' '
      end
    end
    self.send(@@commands[method], message)
  end
end

if __FILE__ == $0
  a = Messenger.new('localhost')
  puts a
  if a.valid?

  end
  # a.end('proof', '23')
end
