# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#

# Class responsible for debug prints
class Debugger

  @@debug_priority = 0
  def self.set_debug_priority(value)
    @@debug_priority = value
  end

  def self.status(priority, *args)
    if priority >= @@debug_priority
      print "STATUS:"
      args.each do |i|
        print " " + i.to_s
      end
      print "\r"
    end
  end

  def self.debug_print(priority, *args)
    if priority >= @@debug_priority
      # Solves race problem with puts
      print "debug:" + priority.to_s
      args.each do |i|
        print " " + i.to_s
      end
      print "\n"
    end
  end
end

## unit testing
if __FILE__ == $0
  Debugger.set_debug_priority(3)
  Debugger.debug_print(4, "oier")
  Debugger.debug_print(2, "Isso nao deve printar")
end
