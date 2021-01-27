<?php

namespace Lib;

class Router {
  private $controller = null;
  private $action = null;
  private $params = array();

  # default constructor and check for validity of request
  public function __construct() {
    $this->convertUrl();
    $this->handleRequest();
  }

  # split URL into controller, action, and params components
  public function convertUrl() {
    if (isset($_SERVER['REQUEST_URI'])) {
      # remove leading/trailing slashes, and exclude query params
      $uri_parts = explode('?', $_SERVER['REQUEST_URI'], 2);
      $url = rtrim($uri_parts[0], '/');
      $url = ltrim($url, '/');

      # filter for malicious input
      $url = filter_var($url, FILTER_SANITIZE_URL);

      # separate path components and store the
      # the controller, action, and any parameters
      $url = explode('/', $url);
      $this->controller = (isset($url[0]) and $url[0] != '') ? $url[0] : 'passes';
      $this->action = (isset($url[1]) and $url[1] != '') ? $url[1] : 'index';
      $this->params = (isset($uri_parts[1]) and $uri_parts[1] != '') ? $uri_parts[1] : null;
    }
  }

  # based on request path, attempt to route to correct location
  public function handleRequest() {
    # attempt to build and call controller action
    $controller_name = ucfirst($this->controller) . 'Controller';
    $controller_file = __DIR__ . '/../App/Controllers/' . $controller_name . '.php';

    if (file_exists($controller_file)) {
      # construct instance of controller
      include_once($controller_file);
      $full_controller_name = "App\\Controllers\\" . $controller_name;
      $this->controller = new $full_controller_name($this->controller);

      # TODO: Pass parameters
      $this->controller->{$this->action}();
    } else {
      echo '404 - could not find controller<br>';
    }
  }
}

?>
