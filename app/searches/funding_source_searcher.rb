# Inventory searcher. 
# Designed to be populated from a search form using a new/create controller model.
#
class FundingSourceSearcher < BaseSearcher

  # Include the fiscal year mixin
  include FiscalYear
  include NumericSanitizers

  # add any search params to this list
  attr_accessor :funding_source_type_id,
                :rural_providers,
                :urban_providers,
                :shared_ride_providers,
                :inter_city_bus_providers,
                :inter_city_rail_providers,
                :show_inactive,
                # Comparator-based (<=>)
                :federal_match_required_comparator,
                :federal_match_required,
                :state_match_required_comparator,
                :state_match_required,
                :local_match_required_comparator,
                :local_match_required,
                # Checkbox-based
                :state_administered_federal_fund,
                # Custom Logic
                :keyword

  # Return the name of the form to display
  def form_view
    'funding_source_search_form'
  end
  # Return the name of the results table to display
  def results_view
    'funding_source_search_results_table'
  end
  
  def cache_variable_name
    FundingSourcesController::INDEX_KEY_LIST_VAR
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

  def funding_source_type_conditions
    FundingSource.where(funding_source_type_id: funding_source_type_id) unless funding_source_type_id.blank?
  end
  
  #---------------------------------------------------
  # Comparator Queries
  #---------------------------------------------------
  
  def federal_match_required_conditions
    unless federal_match_required.blank?
      federal_match_required_as_float = federal_match_required.to_f
      case federal_match_required_comparator
      when "-1" # Before Year X
        FundingSource.where("federal_match_required < ?", federal_match_required_as_float) 
      when "0" # During Year X
        FundingSource.where("federal_match_required = ?", federal_match_required_as_float) 
      when "1" # After Year X
        FundingSource.where("federal_match_required > ?", federal_match_required_as_float) 
      end
    end
  end

  def state_match_required_conditions
    unless state_match_required.blank?
      state_match_required_as_float = state_match_required.to_f
      case state_match_required_comparator
      when "-1" # Before Year X
        FundingSource.where("state_match_required < ?", state_match_required_as_float) 
      when "0" # During Year X
        FundingSource.where("state_match_required = ?", state_match_required_as_float) 
      when "1" # After Year X
        FundingSource.where("state_match_required > ?", state_match_required_as_float) 
      end
    end
  end

  def local_match_required_conditions
    unless local_match_required.blank?
      local_match_required_as_float = local_match_required.to_f
      case local_match_required_comparator
      when "-1" # Before Year X
        FundingSource.where("local_match_required < ?", local_match_required_as_float) 
      when "0" # During Year X
        FundingSource.where("local_match_required = ?", local_match_required_as_float) 
      when "1" # After Year X
        FundingSource.where("local_match_required > ?", local_match_required_as_float) 
      end
    end
  end


  #---------------------------------------------------
  # Simple Checkbox Queries
  #---------------------------------------------------

  def state_administered_federal_fund_conditions
    FundingSource.where(state_administered_federal_fund: true) unless state_administered_federal_fund.eql? "0"
  end

  def rural_providers_conditions
    FundingSource.where(rural_providers: true) unless rural_providers.eql? "0"
  end
  
  def urban_providers_conditions
    FundingSource.where(urban_providers: true) unless urban_providers.eql? "0"
  end
  
  def shared_ride_providers_conditions
    FundingSource.where(shared_ride_providers: true) unless shared_ride_providers.eql? "0"
  end
  
  def inter_city_bus_providers_conditions
    FundingSource.where(inter_city_bus_providers: true) unless inter_city_bus_providers.eql? "0"
  end
  
  def inter_city_rail_providers_conditions
    FundingSource.where(inter_city_rail_providers: true) unless inter_city_rail_providers.eql? "0"
  end
  
  def show_inactive_conditions
    FundingSource.unscoped unless show_inactive.eql? "0"
  end

  #---------------------------------------------------
  # Custom Queries # When the logic does not fall into the above categories, place the method here
  #    Example: joins, ORs, and LIKEs
  #---------------------------------------------------
  def keyword_conditions
    unless keyword.blank?
      searchable_columns = %w(name description) # add any freetext-searchable fields here
      keyword.strip!
      search_str = searchable_columns.map { |x| "#{x} LIKE :keyword"}.to_sentence(:words_connector => " OR ", :two_words_connector => " OR ", :last_word_connector => " OR ")
      FundingSource.where(search_str, :keyword => "%#{keyword}%")
    end
  end

  # In this searcher, we could have no queries (no organization query part), which breaks condition_parts.  
  # Must manually add this to ensure we have at least one query
  def limit_conditions
    FundingSource.all
  end
end