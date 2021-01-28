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
    # parse the url for the respective parts needed, including filtering for malicious inputs
    $full_url = $_SERVER['REQUEST_SCHEME'] . '://' . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'];
    $full_url = filter_var($full_url, FILTER_SANITIZE_URL);
    $url_parts = parse_url($full_url);

    # parse query params if they exist
    $query_params = array();
    if (array_key_exists('query', $url_parts)) {
      parse_str($url_parts['query'], $query_params);
    }

    # remove leading and trailing parts
    $url = rtrim($url_parts['path'], '/');
    $url = ltrim($url, '/');

    # the controller, action, and any parameters
    $url = explode('/', $url);
    $this->controller = (isset($url[0]) and $url[0] != '') ? $url[0] : 'passes';
    $this->action = (isset($url[1]) and $url[1] != '') ? $url[1] : 'index';
    $this->params = $query_params;
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

      # merge controller name as page identifier
      $args = array_merge($this->params, array('page' => $this->controller->name));

      # call controller action with parameters
      $this->controller->{$this->action}($args);
    } else {
      echo '404 - could not find controller<br>';
    }
  }
}

?>
