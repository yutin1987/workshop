#!/bin/sh
CONF=/etc/config/qpkg.conf
QPKG_NAME="momo"
QPKG_PATH=$(/sbin/getcfg $QPKG_NAME Install_Path -f /etc/config/qpkg.conf)

WEB_SHARE=$(/sbin/getcfg SHARE_DEF defWeb -d Qweb -f /etc/config/def_share.info)
WEB_PATH=$(/sbin/getcfg $WEB_SHARE path -f /etc/config/smb.conf)

case "$1" in
  start)
    : ADD START ACTIONS HERE
    ;;

  stop)
    : ADD STOP ACTIONS HERE
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
