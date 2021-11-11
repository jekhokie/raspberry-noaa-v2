<?php

namespace App\Controllers;

use Lib\View;
use Config\Config;

class CapturesController extends \Lib\Controller {
  public function indexAction($args) {
    $capture = $this->loadModel('Capture');
    $total_pages = $capture->totalPages(Config::CAPTURES_PER_PAGE);

    # pagination - and check for sanity
    $page_number = 1;
    if (array_key_exists('page_no', $args) and $args['page_no'] > 0) $page_number = $args['page_no'];
    if ($page_number > $total_pages) $page_number = $total_pages;

    $capture->getList($page_number, Config::CAPTURES_PER_PAGE);
    $args = array_merge($args, array('capture' => $capture,
                                     'cur_page' => $page_number,
                                     'page_count' => $total_pages));

    View::renderTemplate('Captures/index.html', $args);
  }

  public function listImagesAction($args) {
    $capture = $this->loadModel('Capture');
    if (array_key_exists('pass_id', $args) and $args['pass_id'] > 0) $pass_id = $args['pass_id'];

    $capture->getEnhancements($pass_id);
    $capture->getImagePath($pass_id);
    $capture->getGain($pass_id);

    $args = array_merge($args, array('capture' => $capture));

    View::renderTemplate('Captures/show.html', $args);
  }
}

?>
