class SchedulerController < OrganizationAwareController
   
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Scheduler", :scheduler_index_path
  
  # Include the fiscal year mixin
  include FiscalYear
  
  # Controller actions that can be invoked from the view
  DEFER_TO_NEXT_YEAR_ACTION    = '1'
  REHABILITATE_ACTION          = '2'
  REMOVE_FROM_SERVICE_ACTION   = '3'
          
  # Returns the list of assets that are scheduled for replacement/rehabilitation in teh given
  # fiscal year.
  def index

    @year = params[:year].blank? ? next_fiscal_year_year : params[:year].to_i
    @next_fy_year = @year + 1

    # This could be a heterogenous list of assets so make sure that we get a collection of typed assets for the
    # renderers
    @assets = get_assets(@year)        
   
  end
  
  # process a scheduler action. These are generally ajaxed
  def action
    asset = Asset.find_by_object_key(params[:id])
    action_type = params[:action_type]

    @year = params[:year].blank? ? next_fiscal_year_year : params[:year].to_i
    @next_fy_year = @year + 1
  
    if action_type == DEFER_TO_NEXT_YEAR_ACTION
      asset.scheduled_replacement_year = @next_fy_year
      asset.scheduled_rehabilitation_year = nil
      asset.save
      notify_user :notice, "#{asset.asset_subtype}: #{asset.asset_tag} is now scheduled for replacement in #{fiscal_year(@year)}"
    elsif action_type == REHABILITATE_ACTION
      asset.scheduled_replacement_year = nil
      asset.scheduled_rehabilitation_year = @next_fy_year
      asset.save
      notify_user :notice, "#{asset.asset_subtype}: #{asset.asset_tag} is now scheduled for rehabilitation in #{fiscal_year(@year)}"
    elsif action_type == REMOVE_FROM_SERVICE_ACTION
      notify_user :notice, "#{asset.asset_subtype}: #{asset.asset_tag} is now scheduled to be removed from service in #{fiscal_year(@year)}"
    else
      notify_user :alert, "Unknown action"
    end

    @assets = get_assets(@year)        
    
  end
  
  protected
  
  def get_assets(year)

    # This could be a heterogenous list of assets so make sure that we get a collection of typed assets for the
    # renderers
    assets = []
    list = Asset.where('organization_id = ? AND disposition_date IS NULL AND (scheduled_replacement_year = ? OR scheduled_rehabilitation_year = ? OR YEAR(scheduled_disposition_date) = ?)', current_user.organization, year, year, year)   
    list.each do |a|
      assets << Asset.get_typed_asset(a)
    end
    
    assets

  end
      
  private
  
end
