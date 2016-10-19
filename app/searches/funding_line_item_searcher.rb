# Inventory searcher.
# Designed to be populated from a search form using a new/create controller model.
#
class FundingLineItemSearcher < BaseSearcher

  # Include the fiscal year mixin
  include FiscalYear
  include TransamNumericSanitizers

  # add any search params to this list
  attr_accessor :funding_source_type,
                :fy_year,
                :funding_line_item_type,
                # Comparator-based (<=>)
                :amount,
                :amount_comparator,
                # Checkbox-based
                # Custom Logic
                :discretionary_type,
                :organization_id

  # Return the name of the form to display
  def form_view
    'funding_line_item_search_form'
  end
  # Return the name of the results table to display
  def results_view
    'funding_line_item_search_results_table'
  end

  def cache_variable_name
    FundingLineItemsController::INDEX_KEY_LIST_VAR
  end

  # return a select array of fiscal years
  def fiscal_years
    get_fiscal_years
  end

  def initialize(attributes = {})
    super(attributes)
  end


  private

  #---------------------------------------------------
  # Simple Equality Queries
  #---------------------------------------------------

  def fy_year_conditions
    FundingLineItem.where(fy_year: fy_year) unless fy_year.blank?
  end

  def funding_line_item_type_conditions
    FundingLineItem.where(funding_line_item_type_id: funding_line_item_type) unless funding_line_item_type.blank?
  end

  #---------------------------------------------------
  # Comparator Queries
  #---------------------------------------------------

  def amount_conditions
    unless amount.blank?
      amount_as_float = sanitize_to_float(amount)
      case amount_comparator
      when "-1"
        FundingLineItem.where("amount < ?", amount_as_float)
      when "0"
        FundingLineItem.where("amount = ?", amount_as_float)
      when "1"
        FundingLineItem.where("amount > ?", amount_as_float)
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

  def discretionary_type_conditions
    FundingLineItem.joins(:funding_source).where('funding_sources.discretionary_fund = ?', discretionary_type) unless discretionary_type.blank?
  end

  def funding_source_type_conditions
    FundingLineItem.joins(:funding_source => :funding_source_type).where(:funding_source_types => {:id => funding_source_type}) unless funding_source_type.blank?
  end

  def organization_conditions
    if organization_id.blank?
      FundingLineItem.where(organization_id:  user.user_organization_filter.get_organizations.map{|o| o.id})
    else
      FundingLineItem.where(organization_id: organization_id)
    end
  end


end
