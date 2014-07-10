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
  
  # urban/rural types for orgs
  RURAL = 1
  URBAN = 2
  BOTH = 3
  
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
    capital_project = ali.project
    if capital_project.nil?
      Rails.logger.info "ALI is not associated with a capital project."
      return a
    end
    organization = capital_project.organization
    if organization.nil?
      Rails.logger.info "ALI is not associated with an organization."
      return a
    end
    
    Rails.logger.info "Evaluating funding options for ALI #{ali}."
    
    
     # Start to set up the query
    conditions  = []
    values      = []
        
    # Set the fiscal year
    conditions << 'fy_year = ?'
    values << capital_project.fy_year      
    
    # Check for rural compatibility
    if organization.urban_rural_type_id == RURAL or organization.urban_rural_type_id == BOTH
      conditions << 'rural_providers = ?'
      values << 1      
    end
    # Check for urban compatibility
    if organization.urban_rural_type_id == URBAN or organization.urban_rural_type_id == BOTH
      conditions << 'urban_providers = ?'
      values << 1      
    end
    
    #puts conditions.inspect
    #puts values.inspect
    a = FundingSource.where(conditions.join(' AND '), *values)
    
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