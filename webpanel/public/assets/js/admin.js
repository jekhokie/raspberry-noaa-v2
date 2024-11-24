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


$('#confirmDeleteMultiple').on('show.bs.modal', function (event) {
  var ids = [];
  var info = [];
  $('input[type=checkbox]:checked').each(function () {
    var id = $(this).attr("id");
    var satellite_name = $(this).attr("sat-name");
    var elevation = $(this).attr('elevation');
    var pass_start = $(this).attr('pass-start');
    ids.push(id);
    info.push("<p>" + satellite_name + " " + pass_start + "</p>");

  });
  // get data population
  var capture_ids = ids.join([separator = ',']);

  // draw modal and assign vars
  var modal = $(this);
  modal.find('.modal-body p#contents span#satellite-name').html(info);
  modal.find('.modal-footer a#confirmDeletion').attr('href', '/admin/deleteMultiplePass?pass_ids=' + capture_ids);
});

// Event to check if anything selected for Deletion and show or hide button
$(":checkbox").change(function () {
  SetMultipleDeleteButton();
});

// Hide the Multiple Delete button on first load
$( document ).ready(function() {
  $("#multipleDeleteButton").hide();
});

// Event to toggle check boxes for each row
$("#toggleSelectButton").click(function () {
  $('input[type=checkbox]').each(function () {
    this.checked = !this.checked;
  });
  SetMultipleDeleteButton();
});

// common function to set the Multiple Delete button show or hide
function SetMultipleDeleteButton() {
  var itemsSelected = false;
  $('input[type=checkbox]:checked').each(function () {
    itemsSelected = true;
  });
  if (itemsSelected) {
    $("#multipleDeleteButton").show();
  }
  else {
    $("#multipleDeleteButton").hide();
  }
}