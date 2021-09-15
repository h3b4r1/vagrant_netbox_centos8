# setup-centos.sh

# Configure script
set -e # Stop script execution on any error
echo ""; echo "---- Setting up CentOS ----"

# Configure variables
MYHOST=netbox
TESTPOINT=google.com
echo "- Variables set -"

# Test internet connectivity
ping -q -c5 $TESTPOINT > /dev/null 2>&1
 
if [ $? -eq 0 ]
then
	echo "- Internet Ok -"	
else
	echo "- Internet failed -"
fi

# Set system name
echo "- Set name to $MYHOST -"
hostnamectl set-hostname $MYHOST
cat >> /etc/hosts <<EOF
10.0.2.15	$MYHOST $MYHOST.localdomain
EOF

# Sync clock
echo "- Sync Clock -"
cat >> /etc/chrony.conf <<EOF
server 0.au.pool.ntp.org
EOF

systemctl enable --now chronyd.service

# Base OS update
echo "- Update OS -"
dnf -yqe 3 update

echo "---- CentOS setup complete ----"; echo ""
