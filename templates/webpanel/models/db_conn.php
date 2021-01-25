<?php
  class Conn {
    private $con;

    # default constructor
    public function __construct(string $db_dir) {
      $this->con = new SQLite3($db_dir . 'panel.db');
    }

    # get scheduled pass list information
    public function getPasses() {
      $today = strtotime(date('Y-m-d', time()));
      $query = $this->con->query("SELECT sat_name,
                                         is_active,
                                         pass_start,
                                         pass_end,
                                         max_elev
                                  FROM predict_passes
                                  WHERE (pass_start > $today)
                                  ORDER BY pass_start ASC;");
      $passes = [];
      $i = 0;

      while ($row = $query->fetchArray()) {
        $passes[$i] = $row;
        $i++;
      }

      return $passes;
    }

    # get total number of pages to display images given the
    # passed number of images per page
    public function totalPages($img_per_page) {
      $total_pages = $this->con->querySingle("SELECT count() from decoded_passes;");
      return ceil($total_pages/$img_per_page);
    }

    # get a list of images for the given page and total number
    # of configured images per page
    public function getImages($page, $img_per_page) {
      $query = $this->con->prepare("SELECT decoded_passes.id,
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

      $images = [];
      $i = 0;
      while ($row = $result->fetchArray()) {
        $images[$i] = $row;
        $i++;
      }

      return $images;
    }
  }
?>
