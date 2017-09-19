# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#

# Class that administrates connections
class Connector
  @connections = {}
  def initialize
  end
  # Changes host connection to new_host
  def change_host(new_host)
    @connections[:host] = new_host
  end
end
