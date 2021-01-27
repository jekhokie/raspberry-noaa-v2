<?php

namespace Lib;

abstract class Controller {
  public function __construct($name) {
    $this->name = $name;
  }

  # mapping to provide a before and after functionality
  public function __call($name, $args) {
    $method = $name . 'Action';
    $path = explode('\\', get_called_class());

    if (method_exists($this, $method)) {
      if ($this->before() !== false) {
        # add the page name for navigation control
        $args = array_merge($args, array(array('page' => $this->name)));

        call_user_func_array([$this, $method], $args);
        $this->after();
      }
    } else {
      echo '404 - method ' . $method . ' not found<br>';
    }
  }

  protected function before() { }

  protected function after() { }
}

?>
