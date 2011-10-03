Benchmark tool for Fluent event collector
=========================================

## Install

    # genload.rb depends on fluent gem
    $ gem install fluent

## Usage

    Usage: genload [options] <tag> <num>
        -p, --port PORT                  fluent tcp port (default: 24224)
        -h, --host HOST                  fluent host (default: 127.0.0.1)
        -u, --unix                       use unix socket instead of tcp
        -P, --path PATH                  unix socket path (default: /var/run/fluent/fluent.sock)
        -r, --repeat NUM                 repeat number (default: 1)
        -m, --multi NUM                  send multiple records at once (default: 1)
        -c, --concurrent NUM             number of threads (default: 1)
        -s, --size SIZE                  size of a record (default: 100)
        -G, --no-packed                  don't use lazy deserialization optimize


## Examples

    # uses "benchmark.buffered" tag and sends 50,000 records
    # -c: uses 10 threads/connections;
    # -m: one message includes 20 record
    # -r: repeats 100 times
    ruby genload.rb benchamrk.buffered 50000 -c 10 -m 20 -r 100

