{% extends "base.html" %}

{% block stylesheets %}
  <link rel="stylesheet" type="text/css" href="/assets/css/pagination.css">
  <link rel="stylesheet" type="text/css" href="/assets/css/admin.css">
  <link rel="stylesheet" type="text/css" href="/assets/css/setup.css">
{% endblock %}

{% block body %}
  {% if status_msg is defined %}
    {% if status_msg == 'Success' %}
      <div class="alert alert-success alert-dismissible fade show" role="alert">
        {{ lang['successful_delete_capture'] }}
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    {% else %}
      <div class="alert alert-danger alert-dismissible fade show" role="alert">
        {{ status_msg }}
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    {% endif %}
  {% endif %}

 <span><button onclick="saveUpdate()" class="btn btn-danger" id="btn-save">Save And Install Edit</button></span>
Or leave this window to cancel edits.
<div id="editor" class="aceEditor"></div>
<script src="/assets/src/ace.js" type="text/javascript" charset="utf-8"></script>
<script>


function loadFile(filePath) {
  var result = null;
  var xmlhttp = new XMLHttpRequest();
  xmlhttp.open("GET", filePath, false);
  xmlhttp.send();
  if (xmlhttp.status==200) {
    result = xmlhttp.responseText;
  }
  return result;
 }

    var s = loadFile("./assets/php/settings.yml");
    var editor = ace.edit("editor");
    editor.session.setMode('ace/mode/yaml');
    editor.session.setValue(s);



 function saveUpdate() {
   var data = new FormData();
   var  datatosend = editor.getValue();
   data.append("data", datatosend);
   var xhr = new XMLHttpRequest(); 
   xhr.open( 'post', '/assets/php/post.php', true );
   xhr.send(data);
   pop_up('/assets/php/update.php');
 };

function pop_up(url){
window.open(url,'win2','status=no,toolbar=no,scrollbars=yes,titlebar=no,menubar=no,resizable=yes,width=376,height=368,directories=no,location=no') 
}


</script>

{% endblock %}

{% block js_includes %}
  <script src="/assets/js/admin.js"></script>
{% endblock %}
