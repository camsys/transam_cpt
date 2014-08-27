#------------------------------------------------------------------------------
#
# AliAssetMatcherService
#
# Matches an Activity Line Item to assets that could be added to the ALI
#
# The service returns an array of Asset that are suitable for adding to an 
# the given project
#
#------------------------------------------------------------------------------
class AliAssetMatcherService
    
  # Include the ali code mixin
  include AssetAliLookup
    
  #------------------------------------------------------------------------------
  #
  # Match
  #
  # Single entry point. User passes in a an activity line item. The system get 
  # the rest of what it needs from the ALI and its relationships  
  #
  #------------------------------------------------------------------------------  
  def match(ali, options = {})

    a = []
    if ali.nil?
      Rails.logger.info "ALI cannot be nil."
      return a
    end

    # Make sure that the ALI is either a replacement or rehabilitation ALI
    # for road or rail rolling stock assets
    unless ['11', '12'].include? ali.team_ali_code.type
      Rails.logger.info "ALI type is not bus or rail."
      return a
    end
    unless ['12', '14', '15', '16', '17'].include? ali.team_ali_code.category
      Rails.logger.info "ALI category is not an SOGR code."
      return a
    end
    
    capital_project = ali.capital_project
    if capital_project.nil?
      Rails.logger.info "ALI is not associated with a capital project."
      return a
    end

    organization = Organization.get_typed_organization(capital_project.organization)
    if organization.nil?
      Rails.logger.info "ALI is not associated with an organization."
      return a
    end

    unless organization.type_of? :grantee
      Rails.logger.info "ALI must be owned by a Grantee."
      return a      
    end    
    
    Rails.logger.info "Evaluating assets for ALI #{ali}."
    
     # Start to set up the asset query.
    conditions  = []
    values      = []

    # must belong to the org that owns the capital project
    conditions << 'organization_id = ?'
    values << capital_project.organization.id      

    # cant already be disposed
    conditions << 'disposition_date IS NULL'
                
    # cant be scheduled for disposition
    conditions << 'scheduled_disposition_date IS NULL'
    
    # can't already be associated with the ALI
    unless ali.assets.empty?
      conditions << 'id NOT IN (?)'
      values << ali.asset_ids
    end
        
    asset_subtype_ids = []
    # use the mixin to get the correct subtype from the ALI code
    asset_subtypes = asset_subtypes_from_ali_code(ali.team_ali_code.code)
    asset_subtypes.each do |type|
      # add it to our list
      asset_subtype_ids << type.id
    end
    # If there are no matching codes there is nothing else to do
    if asset_subtype_ids.empty?
      Rails.logger.info "There are no matching asset subtypes for code #{ali.team_ali_code.code}."
      return a
    end
    # add to our query
    conditions << 'asset_subtype_id IN (?)'
    values << asset_subtype_ids.uniq
  
    # Check for replacement/rebuild/rehab years    
    if ['12', '16'].include? ali.team_ali_code.category
      conditions << 'scheduled_replacement_year = ?'
      values << capital_project.fy_year
    elsif ['14', '15', '17'].include? ali.team_ali_code.category
      conditions << 'scheduled_rehabilitation_year = ?'
      values << capital_project.fy_year
    end    
    
    Rails.logger.debug conditions.inspect
    Rails.logger.debug values.inspect
    
    a = Asset.where(conditions.join(' AND '), *values).order(:asset_type_id, :asset_subtype_id)

    Rails.logger.debug "Found #{a.size} mathcing assets."

    # return this list
    a    
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