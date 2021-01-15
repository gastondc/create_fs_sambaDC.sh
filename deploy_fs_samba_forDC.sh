
echo ""
read -r -p 'Enter Domain to deploy =  ' longdomain

realm=${longdomain^^}
shortdomain=`echo $realm | awk -F \. '{ print $2 }'`
ip_address=`hostname -I | awk '{ print $1 }'`
ip_gateway=`ip r | grep default | awk '{ print $3 }'`
timezone=America/Argentina/Buenos_Aires

# Generic Conf
TIMESTAMP=`/bin/date +%d-%m-%Y_%T`
linuxdistribution=`awk '{ print $1 }' /etc/issue`

echo "
> check information to proceed to install Samba DC:

> realm    = $realm
> domain   = $shortdomain
> Local IP = $ip_address
> Linuxdistribution = $linuxdistribution
>
>"

DEBIAN_FRONTEND=noninteractive apt install samba samba-testsuite winbind libnss-winbind libpam-winbind acl libpam-krb5 krb5-config krb5-user -y &&


service smbd stop &&
service nmbd stop &&
service winbind stop &&

mv /etc/samba/smb.conf /etc/samba/smb.conf.bak &&
mv /etc/krb5.conf /etc/krb5.conf.original

mkdir /srv/samba/publica &&

cat << EOT > /etc/samba/smb.conf &&
[global]
	security = ADS
	workgroup = $shortdomain
	realm = $realm
	log file = /var/log/samba/%m.log
	log level = 1

	idmap config * : backend = tdb
	idmap config * : range = 3000-7999
   	idmap config $realm :backend = rid
        idmap config $realm :range = 10000-999999
	username map = /etc/samba/user.map

	vfs objects = acl_xattr
	map acl inherit = yes
	store dos attributes = yes

[Publica]
	path = /srv/samba/publica
	read only = no
EOT

cat << EOT > /etc/krb5.conf &&
[libdefaults]
	default_realm = $realm
	dns_lookup_realm = false
	dns_lookup_kdc = true
EOT

cat << EOT > /etc/samba/user.map &&
!root = $realm\Administrator
EOT

echo "Ingresar contraseña de administrator"
net ads join -U administrator &&

/etc/init.d/smbd start &&
/etc/init.d/nmbd start &&
/etc/init.d/winbind start &&
