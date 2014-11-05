$(document).ready(function() {
	
// load the contents for the budget-editing modal when it is shown
$('#add-funds-modal').on('shown.bs.modal', function(e) {
	$('#add-funds-modal').load(
		'/planning/add_funds', 
		{
  			'ali': $(e.relatedTarget).data('ali'),
  			'fiscal_year': $(e.relatedTarget).data('fiscal-year')
		} 
	);
});

// load the contents for the budget-editing modal when it is shown
$('#update-cost-modal').on('shown.bs.modal', function(e) {
  $('#update-cost-modal').load(
    '/planning/update_cost', 
    {
      'ali': $(e.relatedTarget).data('ali'),
      'fiscal_year': $(e.relatedTarget).data('fiscal-year')
    } 
  );
});

// load the contents for the budget-editing modal when it is shown
$('#edit-asset-modal').on('shown.bs.modal', function(e) {
  $('#edit-asset-modal').load(
    '/planning/edit_asset', 
    {
      'id': $(e.relatedTarget).data('id'),
      'fiscal_year': $(e.relatedTarget).data('fiscal-year')
    } 
  );
});

});
