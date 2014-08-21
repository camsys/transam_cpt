class SchedulerController < OrganizationAwareController
   
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Scheduler", :scheduler_index_path
  
  # Include the fiscal year mixin
  include FiscalYear
  
  # Controller actions that can be invoked from the view
  REPLACE_ACTION              = '1'
  REHABILITATE_ACTION         = '2'
  REMOVE_FROM_SERVICE_ACTION  = '3'
    
  YES = '1'
  NO = '0'
  
  BOOLEAN_SELECT = [
    ['Yes', YES],
    ['No', NO]
  ]
          
  # Returns the list of assets that are scheduled for replacement/rehabilitation in teh given
  # fiscal year.
  def index

    year = current_fiscal_year_year
    
    @year_1 = year + 1
    @year_2 = year + 2
    @year_3 = year + 3
    
    # This could be a heterogenous list of assets so make sure that we get a collection of typed assets for the
    # renderers
    @year_1_assets = get_assets(@year_1)        
    @year_2_assets = get_assets(@year_2)        
    @year_3_assets = get_assets(@year_3)        
   
  end
  
  # Process a request to load a scheduler update form. This is ajaxed
  def loader

    @asset = Asset.find_by_object_key(params[:id])
    @current_year = params[:year].to_i
    
    year = current_fiscal_year_year
    
    @year_1 = year + 1
    @year_2 = year + 2
    @year_3 = year + 3

    @actions = []
    @actions << ["Replace",      REPLACE_ACTION]
    @actions << ["Rehabilitate", REHABILITATE_ACTION]
    @actions << ["Remove from service (no replacement)", REMOVE_FROM_SERVICE_ACTION]

    @fiscal_years = []
    (@year_1..@year_1 + 3).each do |yr|
      @fiscal_years << [fiscal_year(yr), yr]
    end
    
  end
  
  # Process a scheduler action. These are generally ajaxed
  def action
    
    proxy = SchedulerActionProxy.new(params[:scheduler_action_proxy])
    
    asset = Asset.find_by_object_key(proxy.object_key)
  
    if proxy.action_id == REPLACE_ACTION
      Rails.logger.debug "Updating asset #{asset.object_key}. New scheduled replacement year = #{proxy.fy_year.to_i}"
      asset.scheduled_replacement_year = proxy.fy_year.to_i
      asset.replacement_reason_type_id = proxy.reason_id.to_i
      asset.save
      #notify_user :notice, "#{asset.asset_subtype}: #{asset.asset_tag} #{asset.description} is scheduled for replacement in #{fiscal_year(proxy.year.to_i)}"
      
    elsif proxy.action_id == REHABILITATE_ACTION
      asset.scheduled_rehabilitation_year = proxy.fy_year.to_i
      asset.scheduled_replacement_year = asset.scheduled_rehabilitation_year + proxy.extend_eul_years.to_i
      asset.save
      #notify_user :notice, "#{asset.asset_subtype}: #{asset.asset_tag} #{asset.description} is now scheduled for replacement in #{fiscal_year(proxy.replace_fy_year.to_i)}"
      
    elsif proxy.action_id == REMOVE_FROM_SERVICE_ACTION
      asset.scheduled_rehabilitation_year = nil
      asset.scheduled_replacement_year = nil
      num_years = proxy.fy_year.to_i - current_fiscal_year_year
      asset.scheduled_disposition_date = Date.today + num_years.years
      asset.save
  
    end

    year = current_fiscal_year_year
    
    @year_1 = year + 1
    @year_2 = year + 2
    @year_3 = year + 3

    # This could be a heterogenous list of assets so make sure that we get a collection of typed assets for the
    # renderers
    @year_1_assets = get_assets(@year_1)        
    @year_2_assets = get_assets(@year_2)        
    @year_3_assets = get_assets(@year_3)        
    
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
