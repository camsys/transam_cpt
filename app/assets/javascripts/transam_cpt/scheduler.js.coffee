$ ->

  $('#schedule_view').on 'ajax:success', (event, xhr, options, data) ->
    # I don't understand why the data isn't already parsed to JSON
    data = data.responseJSON

    if data.action=='destroy_ali'
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

    else if data.action=='set_cost'
      window.transam.show_popup_message(
        data.message.title,
        data.message.text,
        data.message.type
        )
      if data.status=='FAILED'
        $fg = $(event.target).find('.form-group').first()
        $fg.addClass('has-error')
      $('#' + data.object_key + '_ali_panel .ali_cost').html(data.formatted_cost)

