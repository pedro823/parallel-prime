# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#

# Class responsible for all the messaging between systems
# Each connection to another computer has a different messenger
class Messenger
  @@commands = {
    "receive"  => "RCVE",
    "load"     => "LOAD",
    "split"    => "SPLIT",
    "capacity" => "CAP",
    "elect"    => "",
    "answer"   => "ANS"
  }
  # Creates a new messenger
  # @param ip {URI} The URI of the other computer
  # @param port {integer} the port to connect to (Default: 7550)
  def new(ip, port = 7550)
    @socket = TCPSocket.new(ip, port)
    @read_socket = Thread.new do
      while line = socket.gets
        Handler.handle_incoming_message(line)
      end
    end
  end
  def send(command, *args)

  end
  def method_missing(method, *args)
    self.send(@@comands[:method], args)
  end
end
