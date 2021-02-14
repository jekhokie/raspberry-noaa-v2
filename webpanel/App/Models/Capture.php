<?php

namespace App\Models;
use Config\Config;

class Capture extends \Lib\Model {
    public $enhancements;
    public $image_path;
    public $start_epoch;

    # get a list of captures for the given page and total number
    # of configured images per page
    public function getList($page, $img_per_page) {
      $query = $this->db_conn->prepare("SELECT decoded_passes.id,
                                               predict_passes.pass_start,
                                               file_path,
                                               sat_type,
                                               predict_passes.sat_name,
                                               predict_passes.max_elev
                                               FROM decoded_passes
                                               INNER JOIN predict_passes
                                                 ON predict_passes.pass_start = decoded_passes.pass_start
                                               ORDER BY decoded_passes.pass_start DESC LIMIT ? OFFSET ?;");
      $query->bindValue(1, $img_per_page);
      $query->bindValue(2, $img_per_page * ($page-1));
      $result = $query->execute();

      $captures = [];
      $i = 0;
      while ($row = $result->fetchArray()) {
        $captures[$i] = $row;
        $i++;
      }

      $this->list = $captures;
    }

    # get total number of pages to display images given the
    # passed number of images per page
    public function totalPages($images_per_page) {
      $decoded_passes = $this->db_conn->querySingle("SELECT count() FROM decoded_passes;");
      return ceil($decoded_passes/$images_per_page);
    }

    # get the enhancements for the particular capture
    public function getEnhancements($id) {
      $query = $this->db_conn->prepare('SELECT daylight_pass,
                                               sat_type,
                                               file_path,
                                               img_count,
                                               has_spectrogram,
                                               has_pristine
                                        FROM decoded_passes
                                        WHERE id = ?;');
      $query->bindValue(1, $id);
      $result = $query->execute();
      $pass = $result->fetchArray();

      # build enhancement paths based on satellite type
      switch($pass['sat_type']) {
        case 0: // Meteor-M2
          $enhancements = ['-122-rectified.jpg','-col-122-rectified.jpg','-ir-122-rectified.jpg'];
          break;
        case 1: // NOAA
          if ($pass['daylight_pass'] == 1) {
            $enhancements = ['-ZA.jpg','-MCIR.jpg','-MCIR-precip.jpg','-MSA.jpg','-MSA-precip.jpg','-HVC.jpg','-HVC-precip.jpg','-HVCT.jpg','-HVCT-precip.jpg','-therm.jpg'];
          } else {
            $enhancements = ['-ZA.jpg','-MCIR.jpg','-MCIR-precip.jpg','-MSA.jpg','-MSA-precip.jpg','-HVC.jpg','-HVC-precip.jpg','-HVCT.jpg','-HVCT-precip.jpg','-therm.jpg'];
          }
          break;
      }

      # remove any enhancements that do not actually exist for this capture
      foreach ($enhancements as $e) {
        $filepath = Config::IMAGE_PATH . '/' . $pass['file_path'] . $e;
        if (!file_exists($filepath)) {
          $key = array_search($e, $enhancements);
          unset($enhancements[$key]);
        }
      }

      # capture spectrogram if one exists
      if ($pass['has_spectrogram'] == '1') {
        array_push($enhancements, '-spectrogram.png');
      }
      # capture pristine if one exists
      if ($pass['has_pristine'] == '1') {
        array_push($enhancements, '-pristine.jpg');
      }
      
      $this->enhancements = $enhancements;
    }

    # get the image path for the specific image
    public function getImagePath($id) {
      $query = $this->db_conn->prepare('SELECT file_path FROM decoded_passes WHERE id = ?;');
      $query->bindValue(1, $id);
      $result = $query->execute();
      $image = $result->fetchArray();

      $this->image_path = $image['file_path'];
    }

    # get the epoch start time for the capture
    public function getStartEpoch($id) {
      $query = $this->db_conn->prepare('SELECT pass_start FROM decoded_passes WHERE id = ?;');
      $query->bindValue(1, $id);
      $result = $query->execute();
      $res = $result->fetchArray();

      $this->start_epoch = $res['pass_start'];
    }

    # delete a capture by id
    public function deleteById($id) {
      $query = $this->db_conn->prepare('DELETE FROM decoded_passes WHERE id = ?;');
      $query->bindValue(1, $id);
      $result = $query->execute();
    }
}

?>
