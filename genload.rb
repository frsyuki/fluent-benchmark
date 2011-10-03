require 'optparse'
require 'fluent/env'

op = OptionParser.new

op.banner += " <tag> <num>"

port = Fluent::DEFAULT_LISTEN_PORT
host = '127.0.0.1'
unix = false
socket_path = Fluent::DEFAULT_SOCKET_PATH
send_timeout = 20.0
repeat = 1
para = 1
multi = 1
size = 100

config_path = Fluent::DEFAULT_CONFIG_PATH

op.on('-p', '--port PORT', "fluent tcp port (default: #{port})", Integer) {|i|
  port = s
}

op.on('-h', '--host HOST', "fluent host (default: #{host})") {|s|
  host = s
}

op.on('-u', '--unix', "use unix socket instead of tcp", TrueClass) {|b|
  unix = b
}

op.on('-P', '--path PATH', "unix socket path (default: #{socket_path})") {|s|
  socket_path = s
}

op.on('-r', '--repeat NUM', "repeat number (default: 1)", Integer) {|i|
  repeat = i
}

op.on('-m', '--multi NUM', "send multiple records at once (default: 1)", Integer) {|i|
  multi = i
}

op.on('-c', '--concurrent NUM', "number of threads (default: 1)", Integer) {|i|
  para = i
}

op.on('-s', '--size SIZE', "size of a record (default: 100)", Integer) {|i|
  size = i
}

(class<<self;self;end).module_eval do
  define_method(:usage) do |msg|
    puts op.to_s
    puts "error: #{msg}" if msg
    exit 1
  end
end

begin
  op.parse!(ARGV)

  if ARGV.length != 2
    usage nil
  end

  tag = ARGV.shift
  num = ARGV.shift.to_i

rescue
  usage $!.to_s
end

require 'socket'
require 'msgpack'
require 'benchmark'

record = {"col1"=>"a"*size}

connector = Proc.new {
  if unix
    sock = UNIXSocket.open(socket_path)
  else
    sock = TCPSocket.new(host, port)
  end

  opt = [1, send_timeout.to_i].pack('I!I!')  # { int l_onoff; int l_linger; }
  sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_LINGER, opt)

  opt = [send_timeout.to_i, 0].pack('L!L!')  # struct timeval
  sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, opt)

  sock
}

time = Time.now.to_i
data = [tag, [[time, record]]*multi].to_msgpack

repeat.times do
  puts "--- #{Time.now}"
  Benchmark.bm do |x|
    start = Time.now

    lo = num / para / multi
    lo = 1 if lo == 0

    x.report do
      (1..para).map {
        Thread.new do
          sock = connector.call
          lo.times do
            sock.write data
          end
          sock.close
        end
      }.each {|t|
        t.join
      }
    end

    finish = Time.now
    elapsed = finish - start
    size = data.bytesize

    puts "% 10.3f Mbps" % [size*lo*para/elapsed/1000/1000]
    puts "% 10.3f records/sec" % [lo*para*multi/elapsed]
  end

end

