require 'socket'
require 'thread'

socket = TCPSocket.new('localhost', 2000)
while line = socket.gets
  puts line
end
socket.close
