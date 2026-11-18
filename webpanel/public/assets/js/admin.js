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

// [Claude AI edit] START - bulk selection handling for the "Delete selected" button:
// master checkbox toggles all rows, and the submit button stays disabled until
// at least one row is selected (prevents accidental empty submissions)
$(function() {
  function refreshBulkState() {
    var any = $('.bulk-select-item:checked').length > 0;
    $('#bulk-delete-btn').prop('disabled', !any);
  }

  $('#bulk-select-all').on('change', function() {
    $('.bulk-select-item').prop('checked', this.checked);
    refreshBulkState();
  });

  $(document).on('change', '.bulk-select-item', function() {
    if (!this.checked) $('#bulk-select-all').prop('checked', false);
    refreshBulkState();
  });

  refreshBulkState();
});
// [Claude AI edit] END
