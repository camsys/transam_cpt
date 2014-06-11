# Inventory searcher. 
# Designed to be populated from a search form using a new/create controller model.
#
class CapitalProjectSearcher < BaseSearcher

  # Include the fiscal year mixin
  include FiscalYear

  # add any search params to this list
  attr_accessor :organization_id,
                :capital_project_type_id,
                :keywords,
                :fy_year
           
  # Return the name of the form to display
  def form_view
    'capital_project_search_form'
  end
  # Return the name of the results table to display
  def results_view
    'capital_project_search_results_table'
  end

  # return a select array of fiscal years             
  def fiscal_years
    get_fiscal_years
  end  
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  private

  # Performs the query by assembling the conditions from the set of conditions below.
  def perform_query
    # Create a class instance of the asset type which can be used to perform
    # active record queries
    Rails.logger.info conditions
    CapitalProject.where(conditions).limit(MAX_ROWS_RETURNED)  
  end

  # Add any new conditions here. The property name must end with _conditions
  def organization_conditions
    if organization_id.blank?
      ["capital_projects.organization_id in (?)", get_id_list(user.organizations)]
    else
      ["capital_projects.organization_id = ?", organization_id]
    end
  end
  
  def project_type_conditions
    ["capital_projects.capital_project_type_id = ?", capital_project_type_id] unless capital_project_type_id.blank?
  end

  def fiscal_year_conditions
    ["capital_projects.fy_year = ?", fy_year] unless fy_year.blank?
  end
  
  def keyword_conditions
    ["capital_projects.title LIKE ?", "%#{keywords}%"] unless keywords.blank?
  end
  
  def minimum_price_conditions
    #["products.price >= ?", minimum_price] unless minimum_price.blank?
  end
  
  def maximum_price_conditions
    #["products.price <= ?", maximum_price] unless maximum_price.blank?
  end
  
  def category_conditions
    #["products.category_id = ?", category_id] unless category_id.blank?
  end
  
end
