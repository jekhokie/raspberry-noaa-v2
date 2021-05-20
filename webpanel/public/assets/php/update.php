<?php
$home='/home/pi';

putenv("HOME=$home");
$home = getenv("HOME");
echo "<p> php HOME env: ".($home."</p>");

$a = popen('TERM=xterm-256color '.$home.'/raspberry-noaa-v2/install_and_upgrade.sh 2>&1', 'r');

echo '<table width="99%"><tr><td>Terminal Response</td></tr>';

while($b = fgets($a, 4096)) {
  $output= preg_replace('#\\x1b[[][^A-Za-z]*[A-Za-z]#', '', $b);
  $output = preg_replace('/[\(B]/', '', $output);
  $output = preg_replace('[:cntrl:]' , '', $output);
  echo '<tr><td>'.$output.'</td></tr>';
  ob_flush();flush();
}
pclose($a);
?>
