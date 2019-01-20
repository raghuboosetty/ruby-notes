# ------------------------------------------------------------------------
# Basic commands/things
# ------------------------------------------------------------------------
# Syntax check in ruby
ruby -c Gemfile

# ------------------------------------------------------------------------
# Program that prints itself
# ------------------------------------------------------------------------
def method;"def method;;end;puts method()[0, 11] + 34.chr + method + 34.chr + method()[11, method.length-11]";end;puts method()[0, 11] + 34.chr + method + 34.chr + method()[11, method.length-11]

# ------------------------------------------------------------------------
# Array summation conditional
# ------------------------------------------------------------------------
# Logic: 
# if any two array have the first element same then we need to sum up those two array second element and make it as a single array.
two_dim_array = [[1, 1], [2, 4], [3, 9], [1, 1], [3,1]]
results = Hash.new(0)
two_dim_array.each do |k, v|
	results[k] = results[k] + v
end
results.to_a

# ------------------------------------------------------------------------
# gets - console input
# ------------------------------------------------------------------------
def test
  puts "Continue(Y/N):"
  if gets.chomp == "Y"
    puts "Continuing..."
  else
    puts "Stopped!"
  end
end

# ------------------------------------------------------------------------
# Host to IP convert
# ------------------------------------------------------------------------
require 'socket'

# returns AddrInfo object or nil
def get_host_ip(host, port)
  socket = Socket.tcp(host, port)
  return nil unless socket
  address = socket.remote_address
  socket.close
  address
end

# ------------------------------------------------------------------------
# resuce with ensure
# ------------------------------------------------------------------------
def with_ensure
  count = 3
  yield
rescue => e
  puts "#{e.message}"
  raise e
ensure
  if count > 0
    puts "TEST COUNT - #{count}"
  end
end
with_ensure