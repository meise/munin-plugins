#!/usr/lib/evn ruby
# encoding: utf-8

require 'pathname'
require 'thread'

LEASES_FILE = 'dhcp.leases'
IP_ADDRESSES = []
MUTEX = Mutex.new

file = Pathname(LEASES_FILE)
threads, avg_ping, max_ping, min_ping = [], [], [], []

file.each_line do |line|
  unless line =~ /^lease/
    next
  end
  
  IP_ADDRESSES << line.match(/\d+\.\d+\.\d+\.\d+/).to_s
end

p IP_ADDRESSES

for address in IP_ADDRESSES
  threads << Thread.new(address) { |addr|
    data = %x{ping -c 4 #{addr}}.split(/=/).last.split(/\//)
    
    unless data[2].nil?
      MUTEX.synchronize do
        avg_ping << data[2]
      end
    end
    
    unless data[1].nil?
      MUTEX.synchronize do
        min_ping << data[1]
      end
    end
    
    unless data[3].nil?
      MUTEX.synchronize do
        max_ping << data[3]
      end
    end
  }
end

threads.each { |aThread|  aThread.join }

p avg_ping
p min_ping
p max_ping
