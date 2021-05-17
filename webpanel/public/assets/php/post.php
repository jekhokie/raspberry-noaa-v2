<?php

if(!empty($_POST['data'])){
$data = $_POST['data'];
$fname = "settings.yml";// the settings.yml file
$file = fopen("./" .$fname, 'w');//permissions and security to:do
fwrite($file, $data);
fclose($file);
}

?>
