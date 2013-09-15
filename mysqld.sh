#!/bin/sh
# Copyright Abandoned 1996 TCX DataKonsult AB & Monty Program KB & Detron HB
# This file is public domain and comes with NO WARRANTY of any kind

# MySQL daemon start/stop script.

# Usually this is put in /etc/init.d (at least on machines SYSV R4 based
# systems) and linked to /etc/rc3.d/S99mysql and /etc/rc0.d/K01mysql.
# When this is done the mysql server will be started when the machine is
# started and shut down when the systems goes down.

# Comments to support chkconfig on RedHat Linux
# chkconfig: 2345 64 36
# description: A very fast and reliable SQL database engine.

# Comments to support LSB init script conventions
### BEGIN INIT INFO
# Provides: mysql
# Required-Start: $local_fs $network $remote_fs
# Should-Start: ypbind nscd ldap ntpd xntpd
# Required-Stop: $local_fs $network $remote_fs
# Default-Start:  2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: start and stop MySQL
# Description: MySQL is a very fast and reliable SQL database engine.
### END INIT INFO
 
# If you install MySQL on some other places than /usr/local/mysql, then you
# have to do one of the following things for this script to work:
#
# - Run this script from within the MySQL installation directory
# - Create a /etc/my.cnf file with the following information:
#   [mysqld]
#   basedir=<path-to-mysql-installation-directory>
# - Add the above to any other configuration file (for example ~/.my.ini)
#   and copy my_print_defaults to /usr/bin
# - Add the path to the mysql-installation-directory to the basedir variable
#   below.
#
# If you want to affect other MySQL variables, you should make your changes
# in the /etc/my.cnf, ~/.my.cnf or other MySQL configuration files.

# If you change base dir, you must also change datadir. These may get
# overwritten by settings in the MySQL configuration files.

basedir=
datadir=

# The following variables are only set for letting mysql.server find things.

# Set some defaults
MNT_POINT="/mnt/ext"
MYSQL_SOURCE="${MNT_POINT}/opt/source/mysql5.tgz"
MYSQL_DIR="/usr/local/mysql"
ROOT_PART="/mnt/HDA_ROOT"
UPDATEPKG_DIR="${ROOT_PART}/update_pkg"
Project_Name=`/sbin/getcfg Project Name -d null -f /var/default`
DB_Inited="FALSE"

if [ -f ${UPDATEPKG_DIR}/mysql5.tgz ];then
		[ ! -f $MYSQL_SOURCE ] || /bin/rm -f $MYSQL_SOURCE
		MYSQL_SOURCE="${UPDATEPKG_DIR}/mysql5.tgz"
fi
		
if [ -f ${MYSQL_SOURCE} ] && [ ! -d ${MNT_POINT}/opt/mysql ]; then
	/bin/tar xzf ${MYSQL_SOURCE} -C ${MNT_POINT}/opt
	/bin/rm -f ${MYSQL_DIR}
	/bin/ln -sf ${MNT_POINT}/opt/mysql ${MYSQL_DIR}
	/bin/ln -sf /etc/config/my.cnf ${MYSQL_DIR}/my.cnf
	/bin/sync
elif [ -d ${MNT_POINT}/opt/mysql ]; then
	/usr/bin/readlink ${MYSQL_DIR}
	if [ $? != 0 ]; then
		/bin/rm -f ${MYSQL_DIR}
		/bin/ln -sf ${MNT_POINT}/opt/mysql ${MYSQL_DIR}
		/bin/ln -sf /etc/config/my.cnf ${MYSQL_DIR}/my.cnf
		/bin/sync
	fi
fi

pid_file=
server_pid_file=
use_mysqld_safe=1
user=admin
if test -z "$basedir"
then
  basedir=/usr/local/mysql
  bindir=/usr/local/mysql/bin
  if test -z "$datadir"
  then
    datadir=/usr/local/mysql/var
  fi
  sbindir=/usr/local/mysql/sbin
  libexecdir=/usr/local/mysql/libexec
else
  bindir="$basedir/bin"
  if test -z "$datadir"
  then
    datadir="$basedir/data"
  fi
  sbindir="$basedir/sbin"
  libexecdir="$basedir/libexec"
fi

volume_test="HDA_DATA"
volume="HDA_DATA"
/sbin/test -f /usr/local/mysql/bin/mysqld_safe || exit 1
chown -R admin.administrators /usr/local/mysql/
chown -R admin.administrators /usr/local/mysql
chmod 644 /etc/my.cnf
chmod 644 /usr/local/mysql/my.cnf
chmod 644 /etc/config/my.cnf
/usr/bin/readlink "/share/Public" 1>>/dev/null 2>>/dev/null;
if [ $? = 0 ] && [ -d "/share/Public" ]; then
	volume_test=`/sbin/getcfg Public path -f /etc/smb.conf | cut -d '/' -f 3`
	[ "x${volume_test}" = "x" ] || volume=${volume_test}
	if [ ! -d "/share/${volume}/Public" ]; then
		/sbin/setcfg MySQL Enable FALSE
		[ x"${1}" != "xstop" ] && exit 1
	fi
#	volume=`/usr/bin/readlink /share/Public | /bin/cut -d '/' -f 3`
	[ -d /share/${volume}/.@mysql ] || /bin/mkdir /share/${volume}/.@mysql
	if [ ! -d $datadir ]; then
		[ ! -f $datadir ] || /bin/rm $datadir
		/bin/ln -sf /share/${volume}/.@mysql $datadir
	fi
else
	[ x"${1}" != "xstop" ] && exit 1
fi
volume_test=`/sbin/getcfg Public path -f /etc/smb.conf | cut -d '/' -f 3`
if [ "x${volume_test}" = "x" ]; then
	[ x"${1}" != "xstop" ] && exit 1
fi
/bin/mount | /bin/grep "/share/${volume_test}" 1>>/dev/null 2>>/dev/null
if [ $? != 0 ]; then
	[ x"${1}" != "xstop" ] && exit 1
fi

# MySQL 5.1.x doesn't support "innodb_log_arch_dir" variable
/bin/sed -i "/innodb_log_arch_dir/d" /etc/config/my.cnf
#end here

# datadir_set is used to determine if datadir was set (and so should be
# *not* set inside of the --basedir= handler.)
datadir_set=

#
# Use LSB init script functions for printing messages, if possible
#
lsb_functions="/lib/lsb/init-functions"
if test -f $lsb_functions ; then
  source $lsb_functions
else
  log_success_msg()
  {
    echo " SUCCESS! $@"
  }
  log_failure_msg()
  {
    echo " ERROR! $@"
  }
fi

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$basedir/bin
export PATH

mode=$1    # start or stop
shift
other_args="$*"   # uncommon, but needed when called from an RPM upgrade action
           # Expected: "--skip-networking --skip-grant-tables"
           # They are not checked here, intentionally, as it is the resposibility
           # of the "spec" file author to give correct arguments only.

case `echo "testing\c"`,`echo -n testing` in
    *c*,-n*) echo_n=   echo_c=     ;;
    *c*,*)   echo_n=-n echo_c=     ;;
    *)       echo_n=   echo_c='\c' ;;
esac

parse_server_arguments() {
  for arg do
    case "$arg" in
      --basedir=*)  basedir=`echo "$arg" | sed -e 's/^[^=]*=//'`
                    bindir="$basedir/bin"
		    if test -z "$datadir_set"; then
		      datadir="$basedir/data"
		    fi
		    sbindir="$basedir/sbin"
		    libexecdir="$basedir/libexec"
        ;;
      --datadir=*)  datadir=`echo "$arg" | sed -e 's/^[^=]*=//'`
		    datadir_set=1
	;;
      --user=*)  user=`echo "$arg" | sed -e 's/^[^=]*=//'` ;;
      --pid-file=*) server_pid_file=`echo "$arg" | sed -e 's/^[^=]*=//'` ;;
      --use-mysqld_safe) use_mysqld_safe=1;;
      --use-manager)     use_mysqld_safe=0;;
    esac
  done
}

parse_manager_arguments() {
  for arg do
    case "$arg" in
      --pid-file=*) pid_file=`echo "$arg" | sed -e 's/^[^=]*=//'` ;;
      --user=*)  user=`echo "$arg" | sed -e 's/^[^=]*=//'` ;;
    esac
  done
}

wait_for_pid () {
  i=0
  while test $i -lt 35 ; do
    sleep 1
    case "$1" in
      'created')
        test -s $pid_file && i='' && break
        ;;
      'removed')
        test ! -s $pid_file && i='' && break
        ;;
      *)
        echo "wait_for_pid () usage: wait_for_pid created|removed"
        exit 1
        ;;
    esac
    echo $echo_n ".$echo_c"
    i=`expr $i + 1`
  done

  if test -z "$i" ; then
    log_success_msg
  else
    log_failure_msg
  fi
}

# Get arguments from the my.cnf file,
# the only group, which is read from now on is [mysqld]
if test -x ./bin/my_print_defaults
then
  print_defaults="./bin/my_print_defaults"
elif test -x $bindir/my_print_defaults
then
  print_defaults="$bindir/my_print_defaults"
elif test -x $bindir/mysql_print_defaults
then
  print_defaults="$bindir/mysql_print_defaults"
else
  # Try to find basedir in /etc/my.cnf
  conf=/etc/my.cnf
  print_defaults=
  if test -r $conf
  then
    subpat='^[^=]*basedir[^=]*=\(.*\)$'
    dirs=`sed -e "/$subpat/!d" -e 's//\1/' $conf`
    for d in $dirs
    do
      d=`echo $d | sed -e 's/[ 	]//g'`
      if test -x "$d/bin/my_print_defaults"
      then
        print_defaults="$d/bin/my_print_defaults"
        break
      fi
      if test -x "$d/bin/mysql_print_defaults"
      then
        print_defaults="$d/bin/mysql_print_defaults"
        break
      fi
    done
  fi

  # Hope it's in the PATH ... but I doubt it
  test -z "$print_defaults" && print_defaults="my_print_defaults"
fi

#
# Read defaults file from 'basedir'.   If there is no defaults file there
# check if it's in the old (depricated) place (datadir) and read it from there
#

extra_args=""
if test -r "$basedir/my.cnf"
then
  extra_args="-e $basedir/my.cnf"
else
  if test -r "$datadir/my.cnf"
  then
    extra_args="-e $datadir/my.cnf"
  fi
fi

parse_server_arguments `$print_defaults $extra_args mysqld server mysql_server mysql.server`

# Look for the pidfile 
parse_manager_arguments `$print_defaults $extra_args manager`

#
# Set pid file if not given
#
if test -z "$pid_file"
then
  pid_file=$datadir/mysqlmanager-`/bin/hostname`.pid
else
  case "$pid_file" in
    /* ) ;;
    * )  pid_file="$datadir/$pid_file" ;;
  esac
fi
if test -z "$server_pid_file"
then
  server_pid_file=$datadir/`/bin/hostname`.pid
else
  case "$server_pid_file" in
    /* ) ;;
    * )  server_pid_file="$datadir/$server_pid_file" ;;
  esac
fi

# Safeguard (relative paths, core dumps..)
cd $basedir

case "$mode" in
  'start')
    # Start daemon
#added by KenChen@QNAP
		[ `/sbin/getcfg MySQL Enable -u -d FALSE` = TRUE ] || exit 1
		if [ `/sbin/getcfg MySQL DB_Init -u -d FALSE` = FALSE ] && [ -d $datadir ]; then
			/usr/local/mysql/mysql_util.sh --init_db >/dev/null >/dev/null 2>&1
			DB_Inited="TRUE"
			sleep 3
		elif [ -d $datadir ] && [ ! -f $datadir/mysql-bin.index ]; then
			/usr/local/mysql/mysql_util.sh --init_db >/dev/null >/dev/null 2>&1
			DB_Inited="TRUE"
			sleep 3
			/bin/sync
		fi
#end here
    manager=$bindir/mysqlmanager
    if test -x $libexecdir/mysqlmanager
    then
      manager=$libexecdir/mysqlmanager
    elif test -x $sbindir/mysqlmanager
    then
      manager=$sbindir/mysqlmanager
    fi

    echo $echo_n "Starting MySQL"
    if test -x $manager -a "$use_mysqld_safe" = "0"
    then
      if test -n "$other_args"
      then
        log_failure_msg "MySQL manager does not support options '$other_args'"
        exit 1
      fi
      # Give extra arguments to mysqld with the my.cnf file. This script may
      # be overwritten at next upgrade.
      $manager --user=$user --pid-file=$pid_file >/dev/null 2>&1 &
      wait_for_pid created

      # Make lock for RedHat / SuSE
      if test -w /var/lock/subsys
      then
        touch /var/lock/subsys/mysqlmanager
      fi
    elif test -x $bindir/mysqld_safe
    then
      # Give extra arguments to mysqld with the my.cnf file. This script
      # may be overwritten at next upgrade.
      pid_file=$server_pid_file
      #$bindir/mysqld_safe --datadir=$datadir --pid-file=$server_pid_file $other_args >/dev/null 2>&1 &
      #modified by KenChen@QNAP
      $bindir/mysqld_safe --datadir=$datadir --pid-file=$server_pid_file --user=$user $other_args >/dev/null 2>&1 &
      wait_for_pid created

      # Make lock for RedHat / SuSE
      if test -w /var/lock/subsys
      then
        touch /var/lock/subsys/mysql
      fi
    else
      log_failure_msg "Couldn't find MySQL manager or server"
    fi
#added by KenChen    
		if [ "x${Project_Name}" = "xAthens" ] && [ $DB_Inited = "TRUE" ]; then
			/bin/echo "CREATE DATABASE \`wordpress\` ;" > /tmp/wordpress.sql
			/usr/local/mysql/bin/mysql -u root --password=admin < /tmp/wordpress.sql
			/bin/rm -f /tmp/wordpress.sql
		fi
#
#added by bryan Wu 2011/12    
		if [ $DB_Inited = "TRUE" ] && [ -f /usr/local/mysql/CMSDB.sql ] && [ -f /usr/local/mysql/AddCmsUser.sql ] ; then
			/usr/local/mysql/bin/mysql -u root --password=admin < /usr/local/mysql/CMSDB.sql
			/usr/local/mysql/bin/mysql -u root --password=admin < /usr/local/mysql/AddCmsUser.sql
		fi
#end of bryan added
    ;;

  'stop')
    # Stop daemon. We use a signal here to avoid having to know the
    # root password.

    # The RedHat / SuSE lock directory to remove
    lock_dir=/var/lock/subsys/mysqlmanager

    # If the manager pid_file doesn't exist, try the server's
    if test ! -s "$pid_file"
    then
      pid_file=$server_pid_file
      lock_dir=/var/lock/subsys/mysql
    fi

    if test -s "$pid_file"
    then
      mysqlmanager_pid=`cat $pid_file`
      echo $echo_n "Shutting down MySQL"
      kill $mysqlmanager_pid
      # mysqlmanager should remove the pid_file when it exits, so wait for it.
      wait_for_pid removed

      # delete lock for RedHat / SuSE
      if test -f $lock_dir
      then
        rm -f $lock_dir
      fi
    else
	echo "Try to shutting down MySQL"
	_kill=0
	for i in /usr/local/mysql/var/*.pid ;do
		if [ "$i" = "/usr/local/mysql/var/*.pid" ]; then
			break
		fi
		_pidfile=$i
		mysqlmanager_pid=`cat $_pidfile`
		/bin/grep mysqld /proc/$mysqlmanager_pid/stat 2>/dev/null 1>/dev/null
		if [ $? = 0 ]; then
			/bin/kill $mysqlmanager_pid
			wait_for_pid removed
			/bin/rm -f $_pidfile
			_kill=1
		fi
	done
	if [ $_kill = 0 ]; then
      log_failure_msg "MySQL manager or server PID file could not be found!"
	fi
    fi
    ;;

  'restart')
    # Stop the service and regardless of whether it was
    # running or not, start it again.
    $0 stop  $other_args
    $0 start $other_args
    ;;

  'reload')
    if test -s "$server_pid_file" ; then
      mysqld_pid=`cat $server_pid_file`
      kill -HUP $mysqld_pid && log_success_msg "Reloading service MySQL"
      touch $server_pid_file
    else
      log_failure_msg "MySQL PID file could not be found!"
    fi
    ;;

  *)
    # usage
    echo "Usage: $0  {start|stop|restart|reload}  [ MySQL server options ]"
    exit 1
    ;;
esac
