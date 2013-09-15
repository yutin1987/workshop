#!/bin/sh
CONF=/etc/config/qpkg.conf
QPKG_NAME="momo"

QPKG_PATH=$(/sbin/getcfg $QPKG_NAME Install_Path -f /etc/config/qpkg.conf)
QPKG_WEB="${QPKG_PATH}/web"
# /share/HDB_DATA/.qpkg/momo/web

SYS_WEB_INIT="/etc/init.d/Qthttpd.sh"
SYS_WEB_CONFIG="/etc/config/apache/apache.conf"

SYS_WEB_EXTRA="/etc/config/apache/extra"
QPKG_WEB_CONFIG="${SYS_WEB_EXTRA}/apache-${QPKG_NAME}.conf"

case "$1" in
  start)
      echo "register web interface"
      cat > $QPKG_WEB_CONFIG <<EOF
<IfModule alias_module>
  Alias /momo "${QPKG_WEB}"
  <Directory "${QPKG_WEB}">
      AllowOverride None
      Order allow,deny
      Allow from all
  </Directory>
</IfModule>
EOF
      echo "Include ${QPKG_WEB_CONFIG}" >> ${SYS_WEB_CONFIG}
      ${SYS_WEB_INIT} restart &>/dev/null
    ;;

  stop)
    msg "remove web interface"
    sed -i '/${QPKG_WEB_CONFIG}/d' ${SYS_WEB_CONFIG}
    ${SYS_WEB_INIT} restart &>/dev/null
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0
