#!/usr/lib/evn ruby
# encoding: utf-8

=begin
Copyright Daniel Meißner <dm@3st.be>, 2012

This file is part of the munin plugin DhcpActiveLeases.

DhcpActiveLeases is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

DhcpActiveLeases is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with DhcpActiveLeases. If not, see <http://www.gnu.org/licenses/>.
=end

require 'rubygems'
require 'munin'
# stdlib
require 'pathname'
require 'thread'

class DhcpActiveLeases < Munin::Plugin
  LEASES_FILE  = '/var/lib/dhcp/dhcpd.leases'

  graph_attributes "Fetching ",  :category => 'network', :info => ''
  declare_field :active_leases, :label => 'active_leases', :type => :derive, :min => 0

  def retrieve_values
    file   = Pathname(LEASES_FILE)
    leases = 0

    file.each_line do |line|
      if line =~ /active/
        leases += 1
      end
    end

    { :active_leases => leases }
  end
end

DhcpActiveLeases.new.run
