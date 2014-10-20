$ ->

  $('#schedule_view').on 'ajax:success', (event, xhr, options, data) ->
    console.log 'ajax:success'
    # I don't understand why the data isn't already parsed to JSON
    data = data.responseJSON
    $('#confirm_dialog_modal').modal('hide')
    window.transam.show_popup_message(
      data.message.title,
      data.message.text,
      )
    $.scrollTo(
      '#' + data.object_key + '_ali_panel',
      {
        offset: {top: -200}
      }
      )
    $('#' + data.object_key + '_ali_panel').slideUp(
      {
        duration: 'slow'
      }
      )
    $('#year_' + data.year + '_swimlane_badge').html(data.new_ali_count)
