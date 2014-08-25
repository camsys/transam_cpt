# Inventory searcher. 
# Designed to be populated from a search form using a new/create controller model.
#
class CapitalProjectSearcher < BaseSearcher

  # Include the fiscal year mixin
  include FiscalYear
  include NumericSanitizers

  # add any search params to this list
  attr_accessor :organization_id,
                :capital_project_type,
                :capital_project_status_type,
                :team_ali_code,
                :asset_type,
                :asset_subtype,
                # Comparator-based (<=>)
                :fy_year,
                :fy_year_comparator,
                :total_cost,
                :total_cost_comparator,
                # Custom Logic
                :funding_source,
                :keyword,
                :included_assets

  # Return the name of the form to display
  def form_view
    'capital_project_search_form'
  end
  # Return the name of the results table to display
  def results_view
    'capital_project_search_results_table'
  end
  
  def cache_variable_name
    CapitalProjectsController::INDEX_KEY_LIST_VAR
  end

  # return a select array of fiscal years             
  def fiscal_years
    get_fiscal_years
  end  
  
  def initialize(attributes = {})
    super(attributes)
  end    

  protected

  # Performs the query by assembling the conditions from the set of conditions below.
  def perform_query
    # Create a class instance of the asset type which can be used to perform
    # active record queries
    Rails.logger.info "conditions: #{queries.to_sql}"
    queries.limit(MAX_ROWS_RETURNED)  
  end

  # Take a series of methods which return AR queries and reduce them down to a single LARGE query
  def queries
    condition_parts.reduce(:merge)
  end

  def condition_parts
    private_methods(false).grep(/_conditions$/).map { |m| send(m) }.compact
  end
  
  private


  #---------------------------------------------------
  # Simple Equality Queries
  #---------------------------------------------------

  def capital_project_type_conditions
    CapitalProject.where(capital_project_type_id: capital_project_type) unless capital_project_type.blank?
  end

  def capital_project_status_type_conditions
    CapitalProject.where(capital_project_status_type_id: capital_project_status_type) unless capital_project_status_type.blank?
  end

  def team_ali_code_conditions
    CapitalProject.where(team_ali_code_id: team_ali_code) unless team_ali_code.blank?
  end


  
  #---------------------------------------------------
  # Comparator Queries
  #---------------------------------------------------
  def fiscal_year_conditions
    unless fy_year.blank?
      case fy_year_comparator
      when "-1" # Before Year X
        CapitalProject.where("fy_year < ?", fy_year)
      when "1"  # After Year X
        CapitalProject.where("fy_year > ?", fy_year)
      end
    end
  end

  def total_cost_conditions # gonna be tricky...
    unless total_cost.blank?
      total_cost_as_float = sanitize_to_float(total_cost)
      case total_cost_comparator
      when "-1" # Less than X dollars
        CapitalProject.joins(:activity_line_items).group("capital_projects.id").having("sum(activity_line_items.anticipated_cost) < ?", total_cost_as_float)
      when "1"  # More than X dollars
        CapitalProject.joins(:activity_line_items).group("capital_projects.id").having("sum(activity_line_items.anticipated_cost) > ?", total_cost_as_float)
      end
    end
  end


  #---------------------------------------------------
  # Simple Checkbox Queries
  #---------------------------------------------------


  #---------------------------------------------------
  # Custom Queries # When the logic does not fall into the above categories, place the method here
  #    Example: joins, ORs, and LIKEs
  #---------------------------------------------------
  def keyword_conditions
    unless keyword.blank?
      searchable_columns = %w(title description justification project_number) # add any freetext-searchable fields here
      keyword.strip!
      search_str = searchable_columns.map { |x| "#{x} LIKE :keyword"}.to_sentence(:words_connector => " OR ", :last_word_connector => " OR ")
      CapitalProject.where(search_str, :keyword => "%#{keyword}%")
    end
  end

  def asset_type_conditions
    CapitalProject.joins(:activity_line_items => :assets).where(:assets => {asset_type_id: asset_type}) unless asset_type.blank?
  end
  
  def asset_subtype_conditions
    CapitalProject.joins(:activity_line_items => :assets).where(:assets => {asset_subtype_id: asset_subtype}) unless asset_subtype.blank?
  end
  
  # Funding Source type is wrapped up in the structure of funding requests (will have state_funding_source_id or federal_funding_source_id column populated)
  def funding_source_conditions
    unless funding_source.blank?
      case FundingSourceType.find(funding_source).name
      when "Federal"
        CapitalProject.joins(:activity_line_items => {:funding_requests => :federal_funding_line_item})
      when "State"
        CapitalProject.joins(:activity_line_items => {:funding_requests => :state_funding_line_item})
      end
    end
  end

  def organization_conditions
    if organization_id.blank?
      CapitalProject.where(organization_id: get_id_list(user.organizations))
    else
      CapitalProject.where(organization_id: organization_id)
    end
  end
  
end