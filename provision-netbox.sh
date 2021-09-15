# provision-netboxapp.sh

set -e # Stop script execution on any error
echo ""; echo "---- Provisioning Environment ----"

# Install tools
echo "- Installing Tools -"
dnf -yqe 3 install net-tools bind-utils tree python3 python3-mod_wsgi httpd

# Configure firewall
echo "- Update Firewall -"
systemctl enable --now firewalld.service
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Set up netbox
echo "---- Setting up netbox ----"
useradd netbox
# Create netbox folders
mkdir /opt/netbox

# setup project
cd /opt/netbox
pip3 -q install virtualenv
python3 -m virtualenv venv
source ./venv/bin/activate
pip3 -q install netbox
netbox-admin startproject netbox
sed -i 's/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \[\"127.0.0.1\"\]/g' /opt/netbox/netbox/netbox/settings.py

cat >> /opt/netbox/netbox/netbox/settings.py <<EOF
STATIC_ROOT = "/opt/netbox/netbox/static/"
EOF

mkdir /opt/netbox/netbox/media
mkdir /opt/netbox/netbox/static

python /opt/netbox/netbox/manage.py makemigrations
python /opt/netbox/netbox/manage.py migrate
python /opt/netbox/netbox/manage.py collectstatic --noinput

# Insert admin user
echo "from netbox.contrib.auth.models import User; User.objects.filter(username='admin').delete(); User.objects.create_superuser('admin', 'admin@example.com', 'admin')" | python /opt/netbox/netbox/manage.py shell

# Make sure everything is owned by apache
chown -R apache:apache /opt/netbox

# Setup apache server
echo "---- Setting up Apache Server ----"
cat > /etc/httpd/conf.d/netbox.conf <<EOF
WSGIScriptAlias / /opt/netbox/netbox/netbox/wsgi.py
WSGIPythonHome /opt/netbox/venv
WSGIPythonPath /opt/netbox/netbox

<VirtualHost *:80>
        DocumentRoot /opt/netbox

        Alias /static /opt/netbox/netbox/static/
        <Directory "/opt/netbox/netbox/static/">
                Options FollowSymLinks
                Order allow,deny
                Allow from all
                Require all granted
        </Directory>

        Alias /media /opt/netbox/netbox/media/
        <Directory "/opt/netbox/netbox/media/">
                Options FollowSymLinks
                Order allow,deny
                Allow from all
                Require all granted
        </Directory>

                WSGIScriptAlias / /opt/netbox/netbox/netbox/wsgi.py
                ErrorLog /var/log/httpd/netbox-error.log
                CustomLog /var/log/httpd/netbox-access.log combined

        <Directory /opt/netbox/netbox>
                <Files wsgi.py>
                        Require all granted
                </Files>
        </Directory>
</VirtualHost>
EOF

systemctl enable --now httpd.service


echo "---- Environment setup complete ----"; echo ""
echo "------------------------------------------"
echo " With great power, comes great opportunity"
echo "------------------------------------------"
