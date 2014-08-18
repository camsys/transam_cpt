#------------------------------------------------------------------------------
#
# EligibilityService
#
# Matches an organization and capital project to available funding sources by:
#
#   1] evaluating the amount of funds already committed to a fund
#   2] an organizations services (rural/urban etc.)
#   3] the type of project being evaluated
#
# The service returns an array of FundingAmounts that are suitable for funding
# the given project
#
#------------------------------------------------------------------------------
class EligibilityService
    
  #------------------------------------------------------------------------------
  #
  # Evaluate
  #
  # Single entry point. User passes in a an activity line item. The system get 
  # the rest of what it needs from the ALI and its relationships  
  #
  #------------------------------------------------------------------------------  
  def evaluate(ali, options = {})

    a = []
    if ali.nil?
      Rails.logger.info "ALI cannot be nil."
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
    
    Rails.logger.info "Evaluating funding options for ALI #{ali}."
    
    
     # Start to set up the query. Start by fetching a list of matching funds
    conditions  = []
    values      = []
            
    # Check for rural compatibility
    if organization.service_type_rural?
      conditions << 'rural_providers = ?'
      values << 1      
    end
    # Check for urban compatibility
    if organization.service_type_urban?
      conditions << 'urban_providers = ?'
      values << 1      
    end
    # Check for shared ride
    if organization.service_type_shared_ride?
      conditions << 'shared_ride_providers = ?'
      values << 1      
    end
    # Check for ICB
    if organization.service_type_intercity_bus?
      conditions << 'inter_city_bus_providers = ?'
      values << 1      
    end
    # Check for ICW
    if organization.service_type_intercity_rail?
      conditions << 'inter_city_rail_providers = ?'
      values << 1      
    end
    
    eligible_funds = FundingSource.where(conditions.join(' OR '), *values)
    #get the list of fund ids
    fund_ids = []
    eligible_funds.each do |fund|
      fund_ids << fund.id
    end
    # Add an impossible value so the query does not break
    if fund_ids.empty?
      fund_ids << -1
    end
    
    # Get the list of funding line items based on the selected set of funds
    funding_line_items = FundingLineItem.where('active = 1 AND funding_source_id IN (?)', fund_ids).order('fy_year')

    # further filter to remove and funds which are already used up
    funding_line_items.each do |fund|
      if fund.available > 0
        # add this as there are still uncommitted funds available
        a << fund
      end
    end
     
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