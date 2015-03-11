#!/usr/bin/ruby

# This script can be used to add and delete routes from the system's routing
# table in response to allocate/deallocate events in the DHCP server.
#
# To use it, add the following as global dhcpd parameters.
#
#    on commit {
#      execute("/usr/local/sbin/prefix-delegation-routing",
#              "add",
#              binary-to-ascii(16, 8, ":", option dhcp6.ia-pd),
#              client-address,
#              interface);
#    }
#    on release {
#      execute("/usr/local/sbin/prefix-delegation-routing",
#              "del",
#              binary-to-ascii(16, 8, ":", option dhcp6.ia-prefix));
#    }
#    on expiry {
#      execute("/usr/local/sbin/prefix-delegation-routing",
#              "del",
#              binary-to-ascii(16, 8, ":", option dhcp6.ia-prefix));
#    }
#
#

require 'ipaddr'

ACTION = ARGV[0]
IADATA = ARGV[1].split(':').map { |o| o.length == 1 ? "0#{o}" : o }

if ACTION == "add"
	client_address = ARGV[2]
	dev = ARGV[3]

	net = "#{IADATA[25..-1].join.scan(/..../).join(':')}/#{IADATA[24].to_i(16)}"
	route = "#{net} via #{client_address} dev #{dev} proto 66"

	system("ip -6 route change #{route} || ip -6 route add #{route}");
elsif ACTION == "del"
	net = "#{IPAddr.new(IADATA[9..-1].join.scan(/..../).join(':')).to_s}/#{IADATA[8].to_i(16)}"

	system("ip -6 route del #{net}");
end
