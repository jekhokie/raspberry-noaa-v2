$('#confirmDeleteCapture').on('show.bs.modal', function (event) {
  var button = $(event.relatedTarget);

  // get data population
  var capture_id = button.data('capture-id');
  var satellite_name = button.data('sat-name');
  var elevation = button.data('elevation');
  var pass_start = button.data('pass-start');

  // draw modal and assign vars
  var modal = $(this);
  //modal.find('.modal-title').text('New message to ' + recipient)
  modal.find('.modal-body p#contents span#satellite-name').html(satellite_name);
  modal.find('.modal-body p#contents span#pass-start').html(pass_start);
  modal.find('.modal-body p#contents span#capture-elevation').html(elevation);
  modal.find('.modal-footer a#confirmDeletion').attr('href', '/admin/deleteCapture?id=' + capture_id);
});
