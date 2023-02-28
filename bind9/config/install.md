Hello, this is Bing. I can help you with installing bind9 DNS server on LXC.😊

According to the web results¹²³, you need to install bind9 and related tools on your Linux system using the following command:

```bash
sudo apt install bind9 bind9-utils bind9-doc dnsutils
```

Then you need to configure your system to use the new DNS server on your host¹. To do so, edit the `/etc/resolv.conf` file with the following lines:

```bash
nameserver 127.0.0.1
search example.com
```

Replace `example.com` with your domain name.

Next, you need to configure LXC to use a specific DNS server instead of dnsmasq⁵. To do so, create a `/etc/dnsmasq.conf` file with the following content:

```bash
listen-address=127.0.0.1
resolv-file=/etc/resolv.dnsmasq.conf
server=/bit./127.0.0.1#5301
```

The last line tells dnsmasq to forward queries for `.bit.` domains to unbound on port 5301.

Finally, you need to configure bind9 on your host and on your LXC containers⁶. To do so, edit the `/etc/bind/named.conf.options` file on your host and add the following lines:

```bash
acl "trusted" {
    127.0.0.1;
    10.x.x.x/24;
};
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-recursion { trusted; };
    listen-on { 127.0.0.1; };
    listen-on-v6 { none; };
};
```

Replace `10.x.x.x/24` with your LXC network subnet.

Then edit the `/etc/bind/named.conf.local` file on your host and add the following lines:

```bash
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
};
zone "x.x.x.in-addr.arpa" {
    type master;
    file "/etc/bind/db.example.com.rev";
};
```

Replace `example.com` with your domain name and `x.x.x.in-addr.arpa` with your reverse zone.

Then create two files `/etc/bind/db.example.com` and `/etc/bind/db.example.com.rev` on your host and add the records for your domain and LXC containers.

On each LXC container, edit the `/etc/resolv.conf` file and add the following line:

```bash
nameserver 10.x.x.y
```

Replace `10.x.x.y` with your host IP address.

Restart bind9 service on your host using this command:

```bash
sudo systemctl restart bind9.service
```

Test if everything works using these commands:

```bash
dig @localhost example.com +short # should return host IP address

dig @localhost -x 10.x.x.y +short # should return container hostname

dig @localhost bit.ly +short # should return unbound result

ping container-name # should work from host

ping example.com # should work from container

ping bit.ly # should work from both host and container 
```

Source: Conversation with Bing, 2/28/2023(1) Install and configure a DNS server with Bind9 on Linux - Emmanuel Gautier. https://www.emmanuelgautier.com/blog/install-and-configure-dns-server-with-bind9 Accessed 2/28/2023.
(2) How to Setup Bind (DNS Server) on Ubuntu 22.04 - linuxtechi. https://www.linuxtechi.com/install-configure-bind-9-dns-server-ubuntu-debian/ Accessed 2/28/2023.
(3) Getting Started with the BIND DNS Server - ATA Learning. https://adamtheautomator.com/bind-dns-server/ Accessed 2/28/2023.
(4) Configure LXC to use specific DNS server instead of DNSMASQ. https://serverfault.com/questions/884210/configure-lxc-to-use-specific-dns-server-instead-of-dnsmasq Accessed 2/28/2023.
(5) Configure BIND Master DNS Server on Debian 11 / Debian 10. https://computingforgeeks.com/configure-master-bind-dns-server-on-debian/ Accessed 2/28/2023.
(6) How to use the Linux BIND command to install and configure DNS. https://www.redhat.com/sysadmin/dns-configuration-introduction Accessed 2/28/2023.
