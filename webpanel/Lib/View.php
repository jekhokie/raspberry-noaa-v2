<?php

namespace Lib;

use Config\Config;

class View {
  # render a template using twig
  public static function renderTemplate($template, $args = []) {
    static $twig = null;

    # include i18n language file for global inclusion
    $lang = include(__DIR__ . '/../App/Lang/' . Config::LANG . '.php');

    if ($twig === null) {
      $loader = new \Twig\Loader\FilesystemLoader(dirname(__DIR__) . '/App/Views');
      $twig = new \Twig\Environment($loader);
      $twig->addGlobal('lang', $lang);
    }

    echo $twig->render($template, $args);
  }
}

?>
