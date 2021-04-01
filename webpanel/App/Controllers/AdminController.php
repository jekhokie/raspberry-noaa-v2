<?php

namespace App\Controllers;

use Lib\View;
use Config\Config;

class AdminController extends \Lib\Controller {
  # perform authentication prior to access any admin endpoint
  # NOTE: This is a CHEAP method of security and not recommended as
  #       "sufficient" to enable exposing things on the public internet.
  protected function before() {
    if (Config::LOCK_ADMIN == "true") {
      if (!isset($_SERVER['PHP_AUTH_USER']) ||
          ($_SERVER['PHP_AUTH_USER'] != Config::ADMIN_USER || $_SERVER['PHP_AUTH_PW'] != Config::ADMIN_PASS)) {
        header('WWW-Authenticate: Basic realm="raspberry-noaa-v2"');
        header('HTTP/1.0 401 Unauthorized');
        echo 'Auth required';
        exit;
      }
    }
  }

  public function passesAction($args) {
    $pass = $this->loadModel('Pass');
    $pass->getActiveList();
    $args = array_merge($args, array('pass' => $pass,
                                     'admin_action' => 'passes'));
    View::renderTemplate('Admin/passes.html', $args);
  }

  # TODO: This is not very DRY between this and the above function - do
  #       something about this in the future
  public function deletePassAction($args) {
    $lang = include(__DIR__ . '/../Lang/' . Config::LANG . '.php');
    $pass = $this->loadModel('Pass');

    # attempt to delete the user-specified pass
    $status_msg = 'Fail';
    if (array_key_exists('pass_start_id', $args) and $args['pass_start_id'] > 0) {
      $pass_start_id = $args['pass_start_id'];
      $pass->getATJobId($pass_start_id);

      # attempt to remove the job ID
      try {
        echo shell_exec("sudo -u pi atrm " . $pass->at_job_id . " 2>&1");
      } catch (exception $e) {
        error_log("Could not delete pass job ID using atrm for job ID: " . $pass->at_job_id . " - " . $e);
      }

      # attempt to delete the database record
      try {
        $pass->deleteByPassStart($pass_start_id);
      } catch (exception $e) {
        error_log("Could not delete pass from database for pass ID: " . $pass_start_id . " - " . $e);
      }

      $status_msg = 'Success';
    } else {
      $status_msg = $lang['fail_delete_missing_id'];
    }

    $pass->getActiveList();
    $args = array_merge($args, array('pass' => $pass,
                                     'status_msg' => $status_msg,
                                     'admin_action' => 'passes'));
    View::renderTemplate('Admin/passes.html', $args);
  }

  public function capturesAction($args) {
    $capture = $this->loadModel('Capture');
    $total_pages = $capture->totalPages(Config::ADMIN_CAPTURES_PER_PAGE);

    # pagination - and check for sanity
    $page_number = 1;
    if (array_key_exists('page_no', $args) and $args['page_no'] > 0) $page_number = $args['page_no'];
    if ($page_number > $total_pages) $page_number = $total_pages;

    $capture->getList($page_number, Config::ADMIN_CAPTURES_PER_PAGE);
    $args = array_merge($args, array('capture' => $capture,
                                     'cur_page' => $page_number,
                                     'page_count' => $total_pages,
                                     'admin_action' => 'captures'));

    View::renderTemplate('Admin/captures.html', $args);
  }

  # TODO: This is not very DRY between this and the above function - do
  #       something about this in the future
  public function deleteCaptureAction($args) {
    $lang = include(__DIR__ . '/../Lang/' . Config::LANG . '.php');
    $capture = $this->loadModel('Capture');
    $pass = $this->loadModel('Pass');

    # attempt to delete the user-specified capture
    $status_msg = 'Fail';
    if (array_key_exists('id', $args) and $args['id'] > 0) {
      $capture_id = $args['id'];
      $capture->getEnhancements($capture_id);
      $capture->getImagePath($capture_id);

      # delete images from disk
      foreach ($capture->enhancements as $enhancement) {
        $img = Config::IMAGE_PATH . '/' . $capture->image_path . $enhancement;
        $thumb = Config::THUMB_PATH . '/' . $capture->image_path . $enhancement;

        try {
          if (file_exists($img)) { unlink($img); }
        } catch (exception $e) {
          error_log("Could not delete file: " . $img . " - " . $e);
        }

        try {
          if (file_exists($thumb)) { unlink($thumb); }
        } catch (exception $e) {
          error_log("Could not delete file: " . $thumb . " - " . $e);
        }
      }

      # remove capture and pass records from database
      $capture->getStartEpoch($capture_id);
      $capture->deleteById($capture_id);
      $pass->deleteByPassStart($capture->start_epoch);
      $status_msg = 'Success';
    } else {
      $status_msg = $lang['fail_delete_missing_id'];
    }

    $total_pages = $capture->totalPages(Config::ADMIN_CAPTURES_PER_PAGE);

    # pagination - and check for sanity
    $page_number = 1;
    if (array_key_exists('page_no', $args) and $args['page_no'] > 0) $page_number = $args['page_no'];
    if ($page_number > $total_pages) $page_number = $total_pages;

    $capture->getList($page_number, Config::ADMIN_CAPTURES_PER_PAGE);
    $args = array_merge($args, array('capture' => $capture,
                                     'cur_page' => $page_number,
                                     'page_count' => $total_pages,
                                     'status_msg' => $status_msg,
                                     'admin_action' => 'captures'));

    View::renderTemplate('Admin/captures.html', $args);
  }
}

?>
