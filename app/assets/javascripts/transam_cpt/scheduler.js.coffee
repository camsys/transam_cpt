$ ->

  # Set up handlers for swimlane AJAX methods

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

  # Set up swimlane components drag & drop

  # $('.swimlane-container').sortable()
  $('.swimlane-container').disableSelection()
  $('.swimlane-draggable').draggable({
    cursor: "move",
    opacity: 0.7,
    revert: 'invalid',
    revertDuration: 200,
    zIndex: 1000
  })
  $('.swimlane-heading').droppable(
    accept: '.swimlane-draggable',
    # activeClass: 'swimlane-droppable-active',
    # hoverClass: 'swimlane-droppable-hover',
    tolerance: 'pointer',
    drop: (e, ui) ->
      handleSwimlaneDrop(e, ui)
    activate: (e, ui) ->
      # console.log "ACTIVATE"
      droppable_fiscal_year = $(e.target).data('fy')
      draggable_fiscal_year = $(ui.draggable).data('fy')
      if droppable_fiscal_year != draggable_fiscal_year
        $(e.target).addClass('swimlane-droppable-active')
    over: (e, ui) ->
      # console.log "OVER"
      droppable_fiscal_year = $(e.target).data('fy')
      draggable_fiscal_year = $(ui.draggable).data('fy')
      if droppable_fiscal_year != draggable_fiscal_year
        $(e.target).addClass('swimlane-droppable-hover')
    deactivate: ->
      $('.swimlane-heading').removeClass('swimlane-droppable-active')
      $('.swimlane-heading').removeClass('swimlane-droppable-hover')

  )
# end on document load

# Support methods for swimlane component drag and drop

handleSwimlaneDrop = (e, ui) ->
  # console.log "dropped!"
  # console.log e
  # console.log ui
  $target = $(e.target)
  fiscal_year = $target.data('fy')
  # console.log fiscal_year
  $draggable = $(ui.draggable[0])
  object_type = $draggable.data('object-type')
  object_key = $draggable.data('object-key')
  moveObjectToFy(object_type, object_key, fiscal_year)

moveObjectToFy = (object_type, key, year) ->
  $.ajax(
    url: '/scheduler/action'
    method: 'POST'
    data: {scheduler_action_proxy: {action_id: 'move_'+object_type+'_to_fiscal_year', object_key: key, fy_year: year}}
    success: (data) ->
      # console.log data
      location.reload()
    error: (data) ->
      # console.log "error"
      # console.log data
  )

