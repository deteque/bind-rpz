# bind-rpz
DNS Firewall based on Bind and Deteque response policy zones (RPZ)

# Installation
  - create two directories on your server: "/etc/namedb" and "/etc/namedb/zonefiles".  This directory will be bind mounted when the container is run.  The namedb directory will be primariy used to store log files and two config files (named.conf and rndc.conf).  You can create both directories using "mkdir -p /etc/namedb/zonefiles" from your server command prompt.
  
# Create the root.cache file
Because this is a recursive nameserver, we'll need to add a root.cache file.  This file should be placed in the /etc/namedb directory. You can download the latest release of that file by running this command on your server:
  /usr/bin/wget --user=ftp --password=ftp ftp://ftp.rs.internic.net/domain/db.cache -O /etc/namedb/root.cache
 
# Create the rndc.conf file
Bind requires a key file for rndc.  This is normally located at /etc/rndc.conf, but since /etc lies within the docker image, the image has a symlink for rndc.conf that points to /etc/namedb/rndc.conf.  You can generate this file by running rndc-confgen if you do not already have that file.  It would be easiest to run that command on another system but if you don't have that option you can run the bind-rpz image in the foreground and generate the file, then cut and paste the contents into the /etc/namedb/rndc.conf file.  Be sure to chmod that file to 600 (read/write by root only).  To log into the container and generate the rndc.conf file use this command:
  docker run -it --rm bind-rpz bash
  
# Create the named.conf file
The primary configuration file for Bind is named.conf, which is normally located at /etc/named.conf.  Like the rndc.conf file, a symlink under /etc in the container has been added which will point to /etc/namedb/named.conf.  From within the container, "mostly" configured named.conf can be found at /root/bind/named.conf.  The sample file contains everything needed to get the dns server up and running less one thing - the "masters".  At the top of the named.conf file you'll see this header:
  masters DISTRIBUTION-SERVERS {
  };
You will need to add the addresses of the nameservers that will be providing you with the various RPZ feeds.  Each entry must be terminated with a semi-colon.  For example, if you were pulling the rpz zones from 1.1.1.1 and 2.2.2.2 your masters section would look like this:
  masters DISTRIBUTION-SERVERS {
    1.1.1.1;
    2.2.2.2;
  };
  
Commercial Deteque customers will be provided with necessary masters information.  If you're using an RPZ feed from another vendor you'd add their addresses in that section.  Also note that the example template provided assumes the use of Deteque's RPZ feeds.  If using other feeds the zone names would have to be changed to match those you're pulling from your vendor.
 
# Starting the bind-rpz service
If you're running a dual-stack server (a server that supports both IPv4 and IPv6) the easiest way to bring up the docker container is to use the "host" network.  This will insure that your bind logs reflect the correct source ips.  There are several ways you can use to start the bind server, but the easiest would be to use this script:

  docker run \
    --rm \
    --detach \
    --name bind \
    --volume /etc/namedb:/etc/namedb \
    --network host \
    --restart always \
    deteque/bind-rpz
  
  Note that /etc/namedb is a bind mount that will "point" at the /etc/namedb directory on your physical server.
  
