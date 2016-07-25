$(function(){
  $('.edit-estimation-statuses').on('click', function(e) {
    e.preventDefault();

    var $modal = $('#statuses-modal');
    var type = $(this).data('type');

    $modal.find('input:checked').attr('checked', false);

    $('input[name="settings[' + type + '][]"]').each(function() {
      $modal.find('input[type="checkbox"][value="' + $(this).val() + '"]').attr('checked', true);
    });
    $modal.data('type', type);

    showModal('statuses-modal', 600);
  });

  $('.estimation-help').on('click', function(e) {
    e.preventDefault();
    showModal('estimation-help-modal', 600);
  });

  $('#auto-estimate-all').on('ajax:success', function(e, data, status, xhr) {
    $('#flash_notice').remove();
    var $notice = $('<div id="flash_notice" class="flash notice">' + data.response + '</div>');
    $('#content').prepend($notice).show();
  });

  $attrs = $('#all_attributes');

  $attrs.on('click', '#add-system', function(e) {
    e.preventDefault();
    $row = $('.system-knowledge-row:first').clone();
    $row.find('input').val(null);
    $row.find('select').val(null);
    $row.insertBefore($(this).parent());

    $('.system-knowledge-row').each(function(i) {
      $(this).find('select').attr('name', 'system_knowledge[' + i + '][system]');
      $(this).find('input').attr('name', 'system_knowledge[' + i + '][value]');
    });
  });

  $attrs.on('change', 'select[data-company=true]', function(e) {
    e.preventDefault();
    updateIssueFrom($(this).data('path'))
  });

  $attrs.on('click', '.delete-knowledge', function(e) {
    e.preventDefault();
    if ($('.system-knowledge-row').length > 1) {
      $(this).parents('.system-knowledge-row').remove();
    }
  });
});

function selectEstimationStatuses(submitButton) {
  var $modal = $(submitButton).parents('#statuses-modal');
  var type   = $modal.data('type');

  var selectedIds   = [];
  var selectedNames = [];

  $modal.find('input:checked').each(function() {
    selectedIds.push('<input type="hidden" value="'+ $(this).val() + '" name="settings[' + type + '][]" />');
    selectedNames.push($(this).parent().contents().last().text());
  });

  $('#selected-status-ids-' + type).html(selectedIds.join(''));
  $('#selected-status-names-' + type).html(selectedNames.join(', '));

  hideModal(submitButton);
}
