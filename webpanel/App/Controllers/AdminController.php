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

  # run a general server-side event
  protected function runServerEvent($cmd) {
    # headers for event stream
    header('Cache-Control: no-cache');
    header('Content-Type: text/event-stream');
    header('X-Accel-Buffering: no');

    # specify a stdout pipe and the command to launch
    $descriptorspec = array(1 => array("pipe", "w"));

    # start/launch the command specified
    $process = proc_open($cmd, $descriptorspec, $pipes, "/home/pi/raspberry-noaa-v2");

    # check if the process launched successfully
    if (is_resource($process)) {
      # process output of script line by line, sending updates
      while (!feof($pipes[1])) {
        $s = fgets($pipes[1]);
        $data = array("message" => utf8_encode($s));
        echo "data: " . json_encode($data) . PHP_EOL . PHP_EOL;
        ob_flush();
        flush();
      }

      # close open file descriptors and process
      fclose($pipes[1]);
      $retval = proc_close($process);
      $data = array("message" => utf8_encode("Closing processor - return value: " . $retval));
      echo "data: " . json_encode($data) . PHP_EOL . PHP_EOL;
      ob_flush();
      flush();

      # send terminate to close connection
      $data = array("message" => utf8_encode("TERMINATE"));
      echo "data: " . json_encode($data) . PHP_EOL . PHP_EOL;
      ob_flush();
      flush();
    } else {
      # something went wrong starting the process
      $data = array("message" => utf8_encode("Failed to start process"));
      echo "data: " . json_encode($data) . PHP_EOL . PHP_EOL;
      ob_flush();
      flush();
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

  public function configurationsAction($args) {
    $configuration = $this->loadModel('Configuration');
    $configuration->getList();
    $args = array_merge($args, array('configuration' => $configuration,
                                     'admin_action' => 'configuration'));
    View::renderTemplate('Admin/configurations.html', $args);
  }

  public function updateConfigurationsAction($args) {
    $configuration = $this->loadModel('Configuration');

    # attempt to update the parameters in the database
    $status_msg = '';
    foreach ($_POST as $k => $v) {
      try {
        $configuration->updateByKey($k, $v);
      } catch (exception $e) {
        error_log("Could not update configuration key '{}' with value '{}'".format($k, $v));
        $status_msg += $k . ": " . $v . "<br>";
      }
    }

    # if empty status message, everything went well
    if (empty($status_msg)) {
      $status_msg = 'Success';
    }

    $configuration->getList();
    $args = array_merge($args, array('configuration' => $configuration,
                                     'status_msg' => $status_msg,
                                     'admin_action' => 'configuration'));
    View::renderTemplate('Admin/configurations.html', $args);
  }

  public function toolsAction($args) {
    # do work to get and return any available tags
    $tag_list = array('LATEST');
    $current_sha1 = trim(`cd /home/pi/raspberry-noaa-v2/ && git rev-parse HEAD`);
    $current_tag = trim(`cd /home/pi/raspberry-noaa-v2/ && git describe --tags --abbrev=0`);
    $available_tags = array_filter(explode("\n", `cd /home/pi/raspberry-noaa-v2/ && git tag -l`));
    $tag_index = array_search("v1.3.0", $available_tags);

    if (($tag_index + 1) < count($available_tags)) {
      $tag_list = array_slice($available_tags, ($tag_index + 1));
    }

    $args = array_merge($args, array('admin_action' => 'tools',
                                     'current_sha1' => $current_sha1,
                                     'current_tag' => $current_tag,
                                     'tag_list' => $tag_list));
    View::renderTemplate('Admin/tools.html', $args);
  }

  public function gitUpdateTags($args) {
    $cmd = "sudo -u pi git fetch --all --tags 2>&1";
    $this->runServerEvent($cmd);
  }

  # check out the specified tag
  public function gitCheckoutTag($args) {
    $tag = $args['tag'];
    $cmd = "sudo -u pi git checkout tags/" . $tag . " 2>&1";
    $this->runServerEvent($cmd);
  }

  # pull down the latest/edge code
  public function gitPullLatest($args) {
    $cmd = "sudo -u pi git pull origin master 2>&1";
    $this->runServerEvent($cmd);
  }

  # run the install and upgrade script
  public function runUpdate($args) {
    $cmd = "sudo -u pi /home/pi/raspberry-noaa-v2/install_and_upgrade.sh 2>&1";
    $this->runServerEvent($cmd);
  }
}

?>
