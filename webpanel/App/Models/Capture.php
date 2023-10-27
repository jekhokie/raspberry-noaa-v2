<?php

namespace App\Models;
use Config\Config;

class Capture extends \Lib\Model {
  public $enhancements;
  public $image_path;
  public $start_epoch;
  public $travel_direction;
  public $gain;

  # get a list of captures for the given page and total number
  # of configured images per page
  public function getList($page, $img_per_page) {
    $query = $this->db_conn->prepare("SELECT decoded_passes.id,
                                             predict_passes.pass_start,
                                             file_path,
                                             daylight_pass,
                                             sat_type,
                                             gain,
                                             predict_passes.sat_name,
                                             predict_passes.max_elev,
                                             predict_passes.pass_start_azimuth,
                                             predict_passes.direction,
                                             predict_passes.azimuth_at_max
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
                                             has_polar_az_el,
                                             has_polar_direction,
                                             has_pristine,
                                             has_histogram
                                      FROM decoded_passes
                                      WHERE id = ?;');
    $query->bindValue(1, $id);
    $result = $query->execute();
    $pass = $result->fetchArray();

    # build enhancement paths based on satellite type
    switch($pass['sat_type']) {
      case 0: // Meteor
        if ($pass['daylight_pass'] == 1) {
          $enhancements = [
              '-321_corrected.jpg',
              '-321_projected.jpg',
              '-221_corrected.jpg',
              '-221_projected.jpg',
              '-654_corrected.jpg',
              '-654_projected.jpg',
              '-Night_Microphysics_corrected.jpg',
              '-Night_Microphysics_projected.jpg',
              '-Thermal_Channel_corrected.jpg',
              '-Thermal_Channel_projected.jpg',
              '-negative224_corrected.jpg',
              '-negative224_projected.jpg',
              '-4_corrected.jpg',
              '-4_projected.jpg',
              '-equidistant_321.jpg',
              '-equidistant_221.jpg',
              '-equidistant_224.jpg',
              '-equidistant_654.jpg',
              '-equidistant_IR.jpg',
              '-equidistant_thermal.jpg',
              '-equidistant_rain_IR.jpg',
              '-equidistant_rain_221.jpg',
              '-equidistant_rain_224.jpg',
              '-mercator_321.jpg',
              '-mercator_221.jpg',
              '-mercator_224.jpg',
              '-mercator_654.jpg',
              '-mercator_IR.jpg',
              '-mercator_thermal.jpg',
              '-mercator_rain_IR.jpg',
              '-mercator_rain_221.jpg',
              '-mercator_rain_224.jpg',
              '-spread_321.jpg',
              '-spread_221.jpg',
              '-spread_224.jpg',
              '-spread_654.jpg',
              '-spread_IR.jpg',
              '-spread_thermal.jpg',
              '-spread_rain_221.jpg',
              '-spread_rain_224.jpg',
              '-spread_rain_IR.jpg',
              '-equidistant_321_composite.jpg',
              '-equidistant_221_composite.jpg',
              '-equidistant_224_composite.jpg',
              '-equidistant_IR_composite.jpg',
              '-equidistant_thermal_composite.jpg',
              '-equidistant_rain_221_composite.jpg',
              '-equidistant_rain_224_composite.jpg',
              '-equidistant_rain_IR_composite.jpg',
              '-mercator_321_composite.jpg',
              '-mercator_221_composite.jpg',
              '-mercator_224_composite.jpg',
              '-mercator_IR_composite.jpg',
              '-mercator_thermal_composite.jpg',
              '-mercator_rain_221_composite.jpg',
              '-mercator_rain_224_composite.jpg',
              '-mercator_rain_IR_composite.jpg'
          ];
        } else {
          $enhancements = [
              '-654_corrected.jpg',
              '-654_projected.jpg',
              '-Night_Microphysics_corrected.jpg',
              '-Night_Microphysics_projected.jpg',
              '-Thermal_Channel_corrected.jpg',
              '-Thermal_Channel_projected.jpg',
              '-124_corrected.jpg',
              '-124_projected.jpg',
              '-negative224_corrected.jpg',
              '-negative224_projected.jpg',
              '-421_corrected.jpg',
              '-421_projected.jpg',
              '-4_corrected.jpg',
              '-4_projected.jpg',
              '-equidistant_654.jpg',
              '-equidistant_IR.jpg',
              '-equidistant_thermal.jpg',
              '-equidistant_rain_IR.jpg',
              '-spread_rain_IR.jpg',
              '-mercator_654.jpg',
              '-mercator_IR.jpg',
              '-mercator_thermal.jpg',
              '-mercator_rain_IR.jpg',
              '-spread_654.jpg',
              '-spread_IR.jpg',
          ];
        }
        break;
      case 1: // NOAA
        if ($pass['daylight_pass'] == 1) {
          $enhancements = array_map(function($x) { return "-" . $x . ".jpg"; }, explode(' ', Config::NOAA_DAY_ENHANCEMENTS));
        } else {
          $enhancements = array_map(function($x) { return "-" . $x . ".jpg"; }, explode(' ', Config::NOAA_NIGHT_ENHANCEMENTS));
        }
        $satdump_enhancements = [
            "-APT-A.jpg",
            "-APT-B.jpg",
            "-raw.jpg",
            "-A_individual_equalized.jpg",
            "-B_individual_equalized.jpg",
            "Clouds_Underlay.jpg",
            "-224.jpg",
            "-MSA_Rain.jpg",
            "-MCIR_Rain.jpg",
            "-WXtoImg_HVC_N15.jpg",
            "-WXtoImg_HVC_N18.jpg",
            "-WXtoImg_HVC_N19.jpg",
            "-WXtoImg_NO.jpg"
        ];
        $enhancements = array_merge($enhancements, $satdump_enhancements);
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
    # capture polar azimuth elevation graph if one exists
    if ($pass['has_polar_az_el'] == '1') {
      array_push($enhancements, '-polar-azel.jpg');
    }
    # capture polar direction graph if one exists
    if ($pass['has_polar_direction'] == '1') {
      array_push($enhancements, '-polar-direction.png');
    }
    # capture pristine if one exists
    if ($pass['has_pristine'] == '1') {
      array_push($enhancements, '-pristine.jpg');
    }
    if ($pass['has_histogram'] == '1') {
      array_push($enhancements, '-histogram.jpg');
    }

    $this->enhancements = $enhancements;
  }

  # get the image path for the specific capture
  public function getImagePath($id) {
    $query = $this->db_conn->prepare('SELECT file_path FROM decoded_passes WHERE id = ?;');
    $query->bindValue(1, $id);
    $result = $query->execute();
    $image = $result->fetchArray();

    $this->image_path = $image['file_path'];
  }

  # get the gain for the specific capture
  public function getGain($id) {
    $query = $this->db_conn->prepare('SELECT gain FROM decoded_passes WHERE id = ?;');
    $query->bindValue(1, $id);
    $result = $query->execute();
    $image = $result->fetchArray();

    $this->gain = $image['gain'];
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
