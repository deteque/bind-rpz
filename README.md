# bind-rpz
DNS Firewall based on Bind and Deteque response policy zones (RPZ)

# Installation
Create two directories on your server: "/etc/namedb" and "/etc/namedb/zonefiles".  The namedb directory will be primariy used to store log and configuraton files.  The /etc/namedb/zonefile directory will be used to store the RPZ zones and journal files.  The /etc/namedb directory will be bind mounted when the container is run.  You can create both directories by:
  mkdir -p /etc/namedb/zonefiles"
    
# Create the root.cache file
Because this is a recursive nameserver, we'll need to add a root.cache file.  This file should be placed in the /etc/namedb directory. You can download the latest release of that file by running this command on your server:

  /usr/bin/wget --user=ftp --password=ftp ftp://ftp.rs.internic.net/domain/db.cache -O /etc/namedb/root.cache
 
# Create the rndc.conf file
Bind requires a key file for rndc.  This is normally located at /etc/rndc.conf, but since /etc lies within the docker image, the image has a symlink for rndc.conf that points to /etc/namedb/rndc.conf.  You can generate this file by running rndc-confgen if you do not already have that file.  It would be easiest to run that command on another system but if you don't have that option you can run the bind-rpz image in the foreground and generate the file, then cut and paste the contents into the /etc/namedb/rndc.conf file.  Be sure to chmod that file to 600 (read/write by root only).  To log into the container and generate the rndc.conf file use this command:

  docker run -it --rm bind-rpz bash
<pre>
The contents of rndc.conf should look something like this:
  # Start of rndc.conf
  key "rndc-key" {
    algorithm hmac-sha256;
    secret "aBUOt4cFNES7mmpMIEU/5BN5wqFfVeL/Z7itjlb4jjc=";
  };

  options {
    default-key "rndc-key";
    default-server 127.0.0.1;
    default-port 953;
  };
</pre>
  
# Create the named.conf file
The primary configuration file for Bind is named.conf, which is normally located at /etc/named.conf.  Like the rndc.conf file, a symlink under /etc in the container has been added which will point to /etc/namedb/named.conf.  From within the container, a "mostly" configured named.conf can be found at /root/bind/named.conf.  The sample file contains everything needed to get the dns server up and running less two things - the correct rndc secret and host ips in the "masters" section.

Cut and paste rndc's secret that's found in /etc/namedb/rndc.conf file and replace the existing rndc secret that appears in the named.conf template file.  Both secret strings must match.  You'll see a section in named.conf that starts with "key "rndc-key".  That is where you're replace the secret so it matches the secret found in rndc.conf.  Also make sure that the algorithm in both files match.

Next, we need to add the addresses of the servers your server will be pulling the RPZ zones from.  At the top of the named.conf file you'll see this header:
<pre>
  masters DISTRIBUTION-SERVERS {
  };
  </pre>
You will need to add the addresses of the nameservers that will be providing you with the various RPZ feeds.  Each entry must be terminated with a semi-colon.  For example, if you were pulling the rpz zones from 1.1.1.1 and 2.2.2.2 your masters section would look like this:
<pre>
  masters DISTRIBUTION-SERVERS {
    1.1.1.1;
    2.2.2.2;
  };
  </pre>

# Update the Bind ACLS
To prevent your RPZ enabled server from becoming an open recursive, an access list restricts who can query your server.  The default config permits only RFC-1918 addresses; you'll need to edit this ACL to include your addresses if the server is directly connected on the Internet with a public IP.  The current configuration section appears like this:
<pre>
acl LOCAL {
	::1;
	127.0.0.0/8;
	10.0.0.0/8;
	172.16.0.0/12;
	192.168.0.0/16;
};
</pre>  

Commercial Deteque customers will be provided with necessary masters information.  If you're using an RPZ feed from another vendor you'd add their addresses in that section.  Also note that the example template provided assumes the use of Deteque's RPZ feeds.  If using other feeds the zone names would have to be changed to match those you're pulling from your vendor.
 
# Starting the bind-rpz service
If you're running a dual-stack server (a server that supports both IPv4 and IPv6) the easiest way to bring up the docker container is to use the "host" network.  This will insure that your bind logs reflect the correct source ips.  There are several ways you can use to start the bind server, but the easiest would be to use this script:

  <pre>
  docker run \
    --rm \
    --detach \
    --name bind \
    --volume /etc/namedb:/etc/namedb \
    --network host \
    --restart always \
    deteque/bind-rpz
  </pre>
  Note that /etc/namedb is a bind mount that will "point" at the /etc/namedb directory on your physical server.
  
