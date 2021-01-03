<?php
  class Conn {
    private $con;
    public function __construct() {
      $this->con = new SQLite3("/home/pi/raspberry-noaa/panel.db");
    }

    public function getPasses() {
      $today = strtotime(date('Y-m-d', time()));
      $query = $this->con->query("SELECT sat_name, is_active, 
                                    pass_start, pass_end, 
                                    max_elev FROM predict_passes 
                                    WHERE (pass_start > $today) ORDER BY 
                                    pass_start ASC;");
      $passes = [];
      $i = 0;
      while($row = $query->fetchArray()){
        $passes[$i] = $row;
        $i++;
      }
      return $passes;
    }

    public function totalPages($img_per_page) {
      $total_pages = $this->con->querySingle("SELECT count() from decoded_passes;");
      return ceil($total_pages/$img_per_page);
    }

    public function getImages($page, $img_per_page) {
      $query = $this->con->prepare("SELECT  decoded_passes.id, predict_passes.pass_start, 
                                            file_path, sat_type, predict_passes.sat_name, predict_passes.max_elev 
                                            FROM decoded_passes INNER JOIN predict_passes 
                                            ON predict_passes.pass_start = decoded_passes.pass_start
                                            ORDER BY decoded_passes.pass_start DESC LIMIT ? OFFSET ?;");
      $query->bindValue(1, $img_per_page);
      $query->bindValue(2, $img_per_page * ($page-1));
      $result = $query->execute();
      $images = [];
      $i = 0;
      while($row = $result->fetchArray()){
        $images[$i] = $row;
        $i++;
      }
      return $images;
    }

    public function getEnhacements($id) {
      $query = $this->con->prepare('SELECT  daylight_pass, sat_type, img_count
                                            FROM decoded_passes WHERE id = ?;');
      $query->bindValue(1, $id);
      $result = $query->execute();
      $pass = $result->fetchArray();
      switch($pass['sat_type']) {
        case 0: // Meteor-M2
          $enhacements = ['-122-rectified.jpg'];
          break;
        case 1: // NOAA
          if ($pass['daylight_pass'] == 1) {
            $enhacements = ['-ZA.jpg','-MCIR.jpg','-MCIR-precip.jpg','-MSA.jpg','-MSA-precip.jpg','-HVC.jpg','-HVC-precip.jpg','-HVCT.jpg','-HVCT-precip.jpg'];
          } else {
            $enhacements = ['-ZA.jpg','-MCIR.jpg','-MCIR-precip.jpg'];
          }
          break;
        case 2: // ISS
          for ($x = 0; $x <= $pass['img_count']-1; $x++) {
            $enhacements[] = "-$x.png";
          }
          break;
      }
      return $enhacements;
    }

    public function getPath($id) {
      $query = $this->con->prepare('SELECT  file_path FROM decoded_passes 
                                          WHERE id = ?;');
      $query->bindValue(1, $id);
      $result = $query->execute();
      $image = $result->fetchArray();
      return $image['file_path'];
    }
  }
?>
