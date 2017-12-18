#!/bin/bash
echo "+---------------------------------------+";
echo "time:2017/09/24";
echo "tiewangwei website:http://www.tieww.com"
echo "Combination baota linux panel installation zabbix script";
echo "+---------------------------------------+";
pwd=`pwd`;
zabbix_url="http://jaist.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.4.4/";
zabbix_d="zabbix-3.4.4";
zabbix_v="zabbix-3.4.4.tar.gz";
read -p "Enter zabbix database password:" zabbix_pass
read -p "zabbix site directory, for example (/www/default):" webdir
if [[ "$webdir" == "" ]] || [[ ! -e $webdir ]]; then
echo "The input directory is empty or does not exist.";
exit
fi
yum install net-snmp-devel curl curl-devel -y
wget $zabbix_url$zabbix_v;
if [ ! -e $pwd/$zabbix_v ]; then
echo "$pwd/$zabbix_v does not exist, zabbix installation fails.";
exit
fi
tar zxf $pwd/$zabbix_v;
mysql -uzabbix -p$zabbix_pass -e "use zabbix;source $pwd/$zabbix_d/database/mysql/schema.sql;";
echo "schema.sql import was successful.";
mysql -uzabbix -p$zabbix_pass -e "use zabbix;source $pwd/$zabbix_d/database/mysql/images.sql;";
echo "images.sql import was successful.";
mysql -uzabbix -p$zabbix_pass -e "use zabbix;source $pwd/$zabbix_d/database/mysql/data.sql;";
echo "data.sql import was successful.";
sleep 5
groupadd zabbix && useradd zabbix -g zabbix -s /bin/false
ln -s /usr/local/lib/libiconv.so.2 /usr/lib/libiconv.so.2 && /sbin/ldconfig
cd $pwd/$zabbix_d
./configure --prefix=/usr/local/zabbix --enable-server --enable-agent --with-net-snmp --with-libcurl --enable-proxy --with-mysql=/usr/bin/mysql_config && make && make install
if [ "$?" -eq "0" ]; then
echo "zabbix compiled successfully.";
else
echo "zabbix failed to compile.";
exit
fi
sleep 3
ln -s /usr/local/zabbix/sbin/* /usr/local/sbin/ && ln -s /usr/local/zabbix/bin/* /usr/local/bin/
cp /etc/services /etc/servicesbak
cat >>/etc/services<<EOF
# Zabbix
zabbix-agent 10050/tcp # Zabbix Agent
zabbix-agent 10050/udp # Zabbix Agent
zabbix-trapper 10051/tcp # Zabbix Trapper
zabbix-trapper 10051/udp # Zabbix Trapper
EOF
sed -i '/# DBHost=localhost/a\DBHost=localhost' /usr/local/zabbix/etc/zabbix_server.conf
sed -i '/# DBPassword=/a\'DBPassword=$zabbix_pass'' /usr/local/zabbix/etc/zabbix_server.conf
sed -i 's/^# DBSocket=\/t\mp\/\mysql.sock/DBSocket=\/t\mp\/\mysql.sock/g' /usr/local/zabbix/etc/zabbix_server.conf
sed -i 's/^# AlertScriptsPath=${datadir}\/\zabbix\/a\lertscripts/AlertScriptsPath=\/u\sr\/l\ocal\/\zabbix\/\share\/\zabbix\/al\ertscripts/g' /usr/local/zabbix/etc/zabbix_server.conf

sed -i '0,/# Include=/{//s/.*/Include=\/u\sr\/l\ocal\/\zabbix\/\etc\/\zabbix_agentd.conf.d\/\ \n&/}' /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i '/# UnsafeUserParameters=0/a\UnsafeUserParameters=1' /usr/local/zabbix/etc/zabbix_agentd.conf
cp $pwd/zabbix-3.4.4/misc/init.d/fedora/core/zabbix_server /etc/rc.d/init.d/zabbix_server
cp $pwd/zabbix-3.4.4/misc/init.d/fedora/core/zabbix_agentd /etc/rc.d/init.d/zabbix_agentd
chmod +x /etc/rc.d/init.d/zabbix_server && chmod +x /etc/rc.d/init.d/zabbix_agentd
chkconfig zabbix_server on && chkconfig zabbix_agentd on
sed -i "1a BASEDIR=/usr/local/zabbix/" /etc/rc.d/init.d/zabbix_server /etc/rc.d/init.d/zabbix_agentd
cp -r $pwd/zabbix-3.4.4/frontends/php/* $webdir/
chattr -i $webdir/.user.ini
chown www.www -R $webdir/
chattr +i $webdir/.user.ini
service zabbix_server start && service zabbix_server restart 1>/dev/null 2>&1
service zabbix_agentd start && service zabbix_agentd restart 1>/dev/null 2>&1
if [[ -f /tmp/zabbix_server.pid ]] && [[ -f /tmp/zabbix_agentd.pid ]]; then
echo -e "Prompt:　\033[32mzabbix installed successfully.\033[0m";
echo "Tutorial address http://www.tieww.com/2017/09/24/688.html";
else
echo -e "Prompt:　\033[31mzabbix installation failed.\033[0m";
echo "Tutorial address http://www.tieww.com/2017/09/24/688.html";
fi
