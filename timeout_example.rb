require 'timeout'

begin
  status = nil
  Timeout::timeout(2) do
    status = 1
  end
rescue
  puts "Rescued"
  status = 2
end

puts "Status = #{status}"
