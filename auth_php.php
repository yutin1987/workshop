<?php
  $port = exec('/sbin/getcfg System "Web Access Port" -d 8080 -f /etc/config/uLinux.conf');
  $loginURL = "http://127.0.0.1:".$port."/cgi-bin/authLogin.cgi?sid=".$_COOKIE['NAS_SID']."&service=100";
  $root = simplexml_load_file($loginURL);