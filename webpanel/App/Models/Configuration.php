<?php

namespace App\Models;

class Configuration extends \Lib\Model {
  # get a list of configurations
  public function getList() {
    $query = $this->db_conn->query("SELECT config_key,
                                           config_val
                                      FROM configurations
                                  ORDER BY config_key ASC;");

    $configs = [];
    $i = 0;
    while ($row = $query->fetchArray()) {
      $configs[$i] = $row;
      $i++;
    }

    $this->list = $configs;
  }

  # update value by key
  public function updateByKey($config_key, $config_val) {
    $query = $this->db_conn->prepare("UPDATE configurations SET config_val=? WHERE config_key=?");
    $query->bindValue(1, $config_val);
    $query->bindValue(2, $config_key);
    $result = $query->execute();
  }
}

?>
