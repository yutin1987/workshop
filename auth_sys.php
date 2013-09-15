<?php
$php_user = $_SERVER['PHP_AUTH_USER'];
$php_pw = $_SERVER['PHP_AUTH_PW'];

$php_shadow=file_get_contents('/etc/shadow');
preg_match('/admin:([^:]+)/',$php_shadow,$php_admin);
$php_admin = $php_admin[1];
if ($php_admin!==crypt($php_pw, $php_admin)) {
    header('WWW-Authenticate: Basic realm="NAS"');
    header('HTTP/1.0 401 Unauthorized');
    exit;
}else{
  echo 'PASS';
}