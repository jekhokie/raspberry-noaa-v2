<?php

namespace App\Controllers;

use Lib\View;

class PassesController extends \Lib\Controller {
  public function indexAction($args) {
    View::renderTemplate('Passes/index.html', $args);
  }
}

?>
