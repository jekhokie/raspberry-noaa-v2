<?php

namespace Lib;

abstract class Model {
  public $list;
  protected $db_conn;

  public function __construct($db_conn) {
    try {
      $this->db_conn = $db_conn;
    } catch (Exception $e) {
      echo 'Could not connect to database';
    }
  }
}

?>
