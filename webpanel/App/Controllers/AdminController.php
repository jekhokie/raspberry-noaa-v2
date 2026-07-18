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
        echo shell_exec("sudo -u rn2 /usr/bin/atrm " . $pass->at_job_id . " 2>&1");
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

  # [Claude AI edit] START - bulk deletion support ("Delete selected" button)
  #
  # The two private helpers below intentionally perform the exact same steps as
  # the existing deletePassAction/deleteCaptureAction endpoints (which are left
  # untouched to avoid regressions); the new deleteSelected*Action endpoints
  # simply loop those steps over a POSTed list of ids.

  # shared single-pass deletion (atrm unschedule + database record removal)
  private function deleteOnePass($pass, $pass_start_id) {
    $pass->getATJobId($pass_start_id);

    # attempt to remove the job ID
    try {
      echo shell_exec("sudo -u rn2 /usr/bin/atrm " . $pass->at_job_id . " 2>&1");
    } catch (exception $e) {
      error_log("Could not delete pass job ID using atrm for job ID: " . $pass->at_job_id . " - " . $e);
    }

    # attempt to delete the database record
    try {
      $pass->deleteByPassStart($pass_start_id);
    } catch (exception $e) {
      error_log("Could not delete pass from database for pass ID: " . $pass_start_id . " - " . $e);
    }
  }

  # shared single-capture deletion (images + thumbnails + database records)
  private function deleteOneCapture($capture, $pass, $capture_id) {
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
  }

  # deletes every pass whose pass_start id was POSTed via pass_start_ids[]
  # (checkbox selection in the admin passes view)
  public function deleteSelectedPassesAction($args) {
    $lang = include(__DIR__ . '/../Lang/' . Config::LANG . '.php');
    $pass = $this->loadModel('Pass');

    $status_msg = array_key_exists('fail_delete_none_selected', $lang)
                  ? $lang['fail_delete_none_selected'] : 'No items selected';
    if ($_SERVER['REQUEST_METHOD'] === 'POST' &&
        isset($_POST['pass_start_ids']) && is_array($_POST['pass_start_ids'])) {
      $deleted = 0;
      foreach ($_POST['pass_start_ids'] as $pass_start_id) {
        # only accept sane numeric identifiers
        if (is_numeric($pass_start_id) && $pass_start_id > 0) {
          $this->deleteOnePass($pass, intval($pass_start_id));
          $deleted += 1;
        }
      }
      if ($deleted > 0) $status_msg = 'SuccessBulk';
    }

    $pass->getActiveList();
    $args = array_merge($args, array('pass' => $pass,
                                     'status_msg' => $status_msg,
                                     'admin_action' => 'passes'));
    View::renderTemplate('Admin/passes.html', $args);
  }

  # deletes every capture whose id was POSTed via capture_ids[]
  # (checkbox selection in the admin captures view)
  public function deleteSelectedCapturesAction($args) {
    $lang = include(__DIR__ . '/../Lang/' . Config::LANG . '.php');
    $capture = $this->loadModel('Capture');
    $pass = $this->loadModel('Pass');

    $status_msg = array_key_exists('fail_delete_none_selected', $lang)
                  ? $lang['fail_delete_none_selected'] : 'No items selected';
    if ($_SERVER['REQUEST_METHOD'] === 'POST' &&
        isset($_POST['capture_ids']) && is_array($_POST['capture_ids'])) {
      $deleted = 0;
      foreach ($_POST['capture_ids'] as $capture_id) {
        # only accept sane numeric identifiers
        if (is_numeric($capture_id) && $capture_id > 0) {
          $this->deleteOneCapture($capture, $pass, intval($capture_id));
          $deleted += 1;
        }
      }
      if ($deleted > 0) $status_msg = 'SuccessBulk';
    }

    # preserve the page the user was on (submitted as a hidden form field)
    if (isset($_POST['page_no']) && is_numeric($_POST['page_no'])) {
      $args['page_no'] = intval($_POST['page_no']);
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
  # [Claude AI edit] END - bulk deletion support
}

?>
