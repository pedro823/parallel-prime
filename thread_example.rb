require 'socket'
require 'thread'

print_mutex = Mutex.new

def func(prime, print_mutex)
  max = (Math.sqrt(prime)).floor
  b = true
  (2..max).each do |i|
    if prime % i == 0
      print_mutex.synchronize do
        print prime.to_s, " is\'nt prime: ", i.to_s, "\n"
      end
      b = false
      break
    end
  end
  if b
    print_mutex.synchronize do
      print prime, " is prime\n"
    end
  end
end

to_check = [1299989, 1303307, 132633, 1303787]
threads = []
to_check.each do |i|
  threads << Thread.new do
    func(i, print_mutex)
  end
end

threads.each do |t|
  t.join
end
