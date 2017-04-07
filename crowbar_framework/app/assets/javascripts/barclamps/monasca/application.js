
$(document).ready(function($) {
  $('#log_agent_config_manual').on('change', function() {
    var value = $(this).val();

    if (value == 'false') {
      $('#file_path').attr('disabled', 'disabled');
      $('#multiline_pattern').attr('disabled', 'disabled');
    }
    else
    {
      $('#file_path').removeAttr('disabled');
      $('#multiline_pattern').removeAttr('disabled');
    }
  }).trigger('change');
});

