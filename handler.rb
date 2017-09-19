# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#
require 'thread'
require 'socket'
# Class that handles orders from the host
class Handler
  # Handles a line coming from the host
  def self.handle_incoming_message(line)
    puts line
    return line
  end
end

## Unit testing
if __FILE__ == $0
  server = TCPServer.open(7550)
  loop do
    Thread.start(server.accept) do |client|
      a = client.gets
      client.puts(Handler.handle_incoming_message(a))
      client.close
    end
  end
end
