#------------------------------------------------------------------------------
#
# CapitalProjectBuilder
#
# Analyzes an organizations's assets and generates a set of capital projects
# for the organization.
#
#------------------------------------------------------------------------------
class CapitalProjectBuilder
  
  # Include the fiscal year mixin
  include FiscalYear

  # Max number of years to analyze forward
  MAX_FORECASTING_YEARS = SystemConfig.instance.num_forecasting_years   

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  #
  # Main method.
  def build(organization)
    
    Rails.logger.info "Building Capital Projects for #{organization}"
    
    # There are two main types for this implementation -- rehabilitation projects and
    # replacement projects -- we are not doing expansions yet
    
    # Algorithm -- for each FY, get the assets that are scheduled for replacement in that
    # fiscal year, if there are any that are not already in a capital project, create a new project
    # For each group of asset subtypes, create an activity line item and add the assets to the ALI
    # and add the ALI to the project.

    # Get the current fiscal year
    start_year = current_fiscal_year_year
    last_year = start_year + MAX_FORECASTING_YEARS
    
    Rails.logger.debug "start_year = #{start_year}, last_year  #{last_year}"

    # Loop over each asset type    
    asset_types = AssetType.all.each do |asset_type|
      Rails.logger.debug "Processing class = #{asset_type}"
      # Loop over each fiscal year
      (start_year..last_year).each do |year|
        # See how many assets are scheduled for replacement this FY
        assets = Asset.where('organization_id = ? AND asset_type_id = ? AND scheduled_replacement_year = ?', organization.id, asset_type.id, year)
                
        # If there are assets to program we create a new project
        if assets.count > 0
                    
          Rails.logger.debug "Found #{assets.count} assets for FY #{year}"
          # Create a new Capital Project
          project = CapitalProject.new
          project.organization = organization
          project.active = true
          project.emergency = false
          project.capital_project_status_type_id = 1
          project.fy_year = year
          project.team_category = TeamCategory.find_by_code('12') # Purchase/Replacement
          project.team_scope_code = TeamScopeCode.find_by_code('111-00') # Bus Rolling Stock
          project.title = "Replacement of Assets"
          project.description = "Automatically generated by TransAM"
          project.justification = "To be completed"
          project.save
          
          Rails.logger.info "Created new Capital Project #{project.project_number}"
          
          # Create ALIs for each asset subtype in this FY
          asset_subtypes = AssetSubtype.where('asset_type_id = ?', asset_type.id)
          # Filter the asset list by this asset subtype
          asset_subtypes.each do |subtype|
            Rails.logger.debug "Processing subtype = #{subtype}"
            ali_assets = assets.where('asset_subtype_id = ?', subtype.id)
            # if we have some assets we create an ALI
            if ali_assets.count > 0
              Rails.logger.debug "Found #{ali_assets.count} assets for subtype #{subtype}"
              # Create a new ALI
              ali = ActivityLineItem.new
              ali.capital_project = project
              ali.name = "Purchase #{ali_assets.count} replacement #{subtype}"
              ali.team_sub_category = TeamSubCategory.find_by_name(subtype.name)
              ali.save
              
              # Add the assets to this ALI
              ali_assets.each do |a|
                ali.assets << a
              end
            end
          end          
        end        
      end
    end   
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  #------------------------------------------------------------------------------
  #
  # Private Methods
  #
  #------------------------------------------------------------------------------
  private
  
end