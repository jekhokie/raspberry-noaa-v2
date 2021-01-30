<?php

namespace Lib;

use Config\Config;

abstract class Controller {
  protected $db_conn;

  public function __construct($name) {
    $this->name = $name;
    $this->connectToDB();
  }

  # mapping to provide a before and after functionality
  public function __call($name, $args) {
    $method = $name . 'Action';
    $path = explode('\\', get_called_class());

    if (method_exists($this, $method)) {
      if ($this->before() !== false) {
        call_user_func_array([$this, $method], $args);
        $this->after();
      }
    } else {
      echo '404 - method ' . $method . ' not found<br>';
    }
  }

  # runs before controller execution
  protected function before() { }

  # runs after controller execution
  protected function after() { }

  # dynamically loads a model within the controller based
  # on the provided name
  protected function loadModel($name) {
    require '../App/Models/' . $name . '.php';
    $model_obj = '\App\Models\\' . $name;
    return new $model_obj($this->db_conn);
  }

  # establishes connection with database
  private function connectToDB() {
    $this->db_conn = new \SQLite3(Config::DB_FILE);
  }
}

?>
