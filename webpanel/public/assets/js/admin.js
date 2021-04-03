// capture the tag to be used when attempting to update source code
function updateToTag() {
  var tag = document.getElementById("gitTag").value;
  var cmd = 'gitCheckoutTag?tag=' + tag;
  runCommand(cmd);
}

// run a command and pipe the output to the console viewer
function runCommand($cmd) {
  // check for server-sent event support and execute if available
  if (typeof(EventSource) !== "undefined") {
    var source = new EventSource($cmd);

    // log events
    source.onopen = function() { console.log("Connection to server opened."); };
    source.onerror = function(err) { console.error("EventSource failed:", err); };

    // launch the console output modal
    $("div#consoleOutputModal").modal("show");

    // handle message updates
    var consoleOut = document.getElementById("consoleOutputArea");
    source.onmessage = function(e) {
      var result = JSON.parse(e.data);

      // check if we received a termination message so we
      // can close the connection
      if (result.message == "TERMINATE") {
        source.close();
        console.log("Connection to server closed.");
      } else {
        // else append to console output
        consoleOut.innerHTML += result.message + "<br>";
        consoleOut.scrollTop = consoleOut.scrollHeight;
      }
    };
  } else {
    document.getElementById("configUpdates").innerHTML = "No server-sent events support - please check the server for updates";
  }
}

$('#confirmDeletePass').on('show.bs.modal', function (event) {
  var button = $(event.relatedTarget);

  // get data population
  var pass_start_id = button.data('pass-start-id');
  var satellite_name = button.data('sat-name');
  var pass_start = button.data('pass-start');
  var pass_end = button.data('pass-end');

  // draw modal and assign vars
  var modal = $(this);
  modal.find('.modal-body p#contents span#satellite-name').html(satellite_name);
  modal.find('.modal-body p#contents span#pass-start').html(pass_start);
  modal.find('.modal-body p#contents span#pass-end').html(pass_end);
  modal.find('.modal-footer a#confirmDeletion').attr('href', '/admin/deletePass?pass_start_id=' + pass_start_id);
});

$('#confirmDeleteCapture').on('show.bs.modal', function (event) {
  var button = $(event.relatedTarget);

  // get data population
  var capture_id = button.data('capture-id');
  var satellite_name = button.data('sat-name');
  var elevation = button.data('elevation');
  var pass_start = button.data('pass-start');

  // draw modal and assign vars
  var modal = $(this);
  modal.find('.modal-body p#contents span#satellite-name').html(satellite_name);
  modal.find('.modal-body p#contents span#pass-start').html(pass_start);
  modal.find('.modal-body p#contents span#capture-elevation').html(elevation);
  modal.find('.modal-footer a#confirmDeletion').attr('href', '/admin/deleteCapture?id=' + capture_id);
});
