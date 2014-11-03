$ ->

  # Set up handlers for swimlane AJAX methods.


  # Other handlers:


  setupModalHandlers()
  setupSwimlaneDragging()

#######################
# end on document load
#######################

# Support methods for swimlane component drag and drop

# rotate the caret when ALI is collapsed/shown
toggle_ali = (e, state) ->
  s = "[data-target='#" + e.target.id + "']"
  t = $('.ali-heading').find(s)
  if state=='hide'
    t.removeClass('fa-rotate-90')
  else
    t.addClass('fa-rotate-90')


window.setupModalHandlers = () ->
  console.log "setupModalHandlers"
  # rotate caret icon on ALI header when it is shown/collapsed
  $('.swimlane-draggable .panel-body').on 'show.bs.collapse', (e) ->
    toggle_ali(e, 'show')
  $('.swimlane-draggable .panel-body').on 'hide.bs.collapse', (e) ->
    toggle_ali(e, 'hide')

  # load the contents for the asset-editing modal when it is shown
  $('#asset-edit-modal').on 'show.bs.modal', (e) ->
    $('#asset-edit-modal').load(
      '/scheduler/edit_asset_in_modal',
      {'id': $(e.relatedTarget).data('id'), 'year': $(e.relatedTarget).data('year')}
    )
    
  # load the contents for the update cost modal when it is shown
  $('#ali-update-cost-modal').on 'show.bs.modal', (e) ->
    $('#ali-update-cost-modal').load(
      '/scheduler/update_cost_modal',
      {'capital_project': $(e.relatedTarget).data('capital-project'), 'ali': $(e.relatedTarget).data('ali')}
    )

  # load the contents for the fundiong plan modal when it is shown
  $('#ali-add-funding-plan-modal').on 'show.bs.modal', (e) ->
    $('#ali-add-funding-plan-modal').load(
      '/scheduler/add_funding_plan_modal',
      {'capital_project': $(e.relatedTarget).data('capital-project'), 'ali': $(e.relatedTarget).data('ali')}
    )


# Set up swimlane components drag & drop
# Note we make this a global function so that index_scripts.html.erb can refer to it as well.
window.setupSwimlaneDragging = () ->
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
    tolerance: 'pointer',
    drop: (e, ui) ->  
      handleSwimlaneDrop(e, ui)
    activate: (e, ui) ->
      droppable_fiscal_year = $(e.target).data('fy')
      draggable_fiscal_year = $(ui.draggable).data('fy')
      if droppable_fiscal_year != draggable_fiscal_year
        $(e.target).addClass('swimlane-droppable-active')
    over: (e, ui) ->
      droppable_fiscal_year = $(e.target).data('fy')
      draggable_fiscal_year = $(ui.draggable).data('fy')
      if droppable_fiscal_year != draggable_fiscal_year
        $(e.target).addClass('swimlane-droppable-hover')
    deactivate: ->
      $('.swimlane-heading').removeClass('swimlane-droppable-active')
      $('.swimlane-heading').removeClass('swimlane-droppable-hover')
  )

# When an item is dropped on a swimlane header, dispatch action
handleSwimlaneDrop = (e, ui) ->
  $target = $(e.target)
  fiscal_year = $target.data('fy')
  $draggable = $(ui.draggable[0])
  object_type = $draggable.data('object-type')
  object_key = $draggable.data('object-key')
  moveObjectToFy(object_type, object_key, fiscal_year)

# Move either an ALI or asset to another year.
moveObjectToFy = (object_type, key, year) ->  
  if object_type == 'asset'
    url = '/scheduler/scheduler_action'
    post_data = {scheduler_action_proxy: {action_id: 'move_'+object_type+'_to_fiscal_year', object_key: key, fy_year: year}}
  else
    url = '/scheduler/scheduler_ali_action'
    post_data = {invoke: 'move_'+object_type+'_to_fiscal_year', ali: key, scheduler_action_proxy: {object_key: key, fy_year: year}}
  $.ajax(
    url: url
    method: 'POST'
    data: post_data
    beforeSend: () ->
      $('#processing-modal').modal('show')
    complete: () ->
      $('#processing-modal').modal('hide')
    success: (data) ->
      eval(data)
      setupSwimlaneDragging()
    error: (data) ->
      # console.log "error"
      # console.log data
  )
