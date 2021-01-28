<?php

namespace App\Controllers;

use Lib\View;

class PassesController extends \Lib\Controller {
  public function indexAction($args) {
    $pass = $this->loadModel('Pass');
    $pass->getList();
    $args = array_merge($args, array('pass' => $pass));
    View::renderTemplate('Passes/index.html', $args);
  }
}

?>
