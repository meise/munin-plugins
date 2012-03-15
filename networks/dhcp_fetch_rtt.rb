#!/usr/lib/evn ruby
# encoding: utf-8

require 'rubygems'
require 'munin'
# stdlib
require 'pathname'
require 'thread'

class FetchRtt < Munin::Plugin
  LEASES_FILE  = ENV['leases_file'] ||= '/var/lib/dhcp/dhcpd.leases'
  IP_ADDRESSES = []
  MUTEX        = Mutex.new

  graph_attributes "Fetching round trip times inside a network, based on ip addresses located in dhcp.leases",  :category => 'network'
  
  declare_field :min, :label => 'min_delay', :type => :derive, :min => 0
  declare_field :avg, :label => 'avg_delay', :type => :derive, :min => 0
  declare_field :max, :label => 'max_delay', :type => :derive, :min => 0

  def retrieve_values
    
    file = Pathname(LEASES_FILE)
    
    threads, avg_ping, max_ping, min_ping = [], [], [], []
    
    file.each_line do |line|
      unless line =~ /^lease/
        next
      end
      
      IP_ADDRESSES << line.match(/\d+\.\d+\.\d+\.\d+/).to_s
    end
    
    # created for each ip address in leases file a thread
    for address in IP_ADDRESSES
      threads << Thread.new(address) { |addr|
        data = %x{ping -c 4 #{addr}}.split(/=/).last.split(/\//)
    
        unless data[1].nil?
          MUTEX.synchronize do
            avg_ping << data[1]
          end
        end
        
        unless data[0].nil? or data[0] =~ /Destination|bytes/
          MUTEX.synchronize do
            min_ping << data[0].chomp.strip
          end
        end
        
        unless data[2].nil?
          MUTEX.synchronize do
            max_ping << data[2]
          end
        end
      }
    end
    
    threads.each do |thread|
      thread.join
    end  

    { :min => min_ping.min, :avg => avg(avg_ping), :max => max_ping.max }
  end
  
  private
  
  def avg(array)
    sum = array.inject do  |sum, el|
      sum.to_f + el.to_f
    end
  
   result = sum.to_f / array.size
  end
end

FetchRtt.new.run
