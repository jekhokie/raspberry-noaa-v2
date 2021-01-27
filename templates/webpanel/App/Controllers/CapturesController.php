<?php

namespace App\Controllers;

use Lib\View;

class CapturesController extends \Lib\Controller {
  public function indexAction($args) {
    View::renderTemplate('Captures/index.html', $args);
  }
}

?>
