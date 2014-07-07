#------------------------------------------------------------------------------
#
# FundingSource
#
# Represents a funding source in TransAM. Each funding source has a set of match
# rules and a set of agency type rules (urban/rural/shared ride etc.)
#
#------------------------------------------------------------------------------
class FundingSource < ActiveRecord::Base
    
  # Include the unique key mixin
  include UniqueKey
  # Include the fiscal year mixin
  include FiscalYear

  #------------------------------------------------------------------------------
  # Overrides
  #------------------------------------------------------------------------------
  
  #require rails to use the object key as the restful parameter. All URLS will be of the form
  # /funding_source/{object_key}/...
  def to_param
    object_key
  end
  
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize                  :set_defaults

  # Always generate a unique object key before saving to the database
  before_validation(:on => :create) do
    generate_unique_key(:object_key)
  end
  
  # Create a list of funding amounts after a funcing source has been created
  after_create do    
    create_funding_amounts
  end
            
  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------

  # Has a single funding source type
  belongs_to  :funding_source_type

  # Each funding source was created and updated by a user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by_id"
  belongs_to :updator, :class_name => "User", :foreign_key => "updated_by_id"
  
  # Has many funding amounts
  has_many    :funding_amounts, :dependent => :destroy
        
  accepts_nested_attributes_for :funding_amounts, :reject_if => lambda{|a| a[:amount].blank?}, :allow_destroy => true
  
  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => true, :uniqueness => true
  validates :name,                              :presence => true
  validates :description,                       :presence => true
  validates :funding_source_type_id,            :presence => true

  validates :created_by_id,                     :presence => :true
  validates :updated_by_id,                     :presence => :true

  validates :state_match_requried,              :numericality => {:greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 100.0}, :allow_nil => :true
  validates :federal_match_requried,            :numericality => {:greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 100.0}, :allow_nil => :true
  validates :local_match_requried,              :numericality => {:greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 100.0}, :allow_nil => :true

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  
  # default scope
  default_scope { where(:active => true) }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    :name, 
    :description,
    :funding_source_type_id,
    :state_match_requried,
    :federal_match_requried,
    :local_match_requried, 
    :external_id,
    :state_administered_federal_fund,
    :bond_fund,
    :formula_fund,
    :non_committed_fund,
    :contracted_fund,
    :discretionary_fund,
    :rural_providers,
    :urban_providers,
    :shared_rider_providers,
    :inter_city_bus_providers,
    :inter_city_rail_providers,
    :active,
    :funding_amounts_attributes => [FundingAmount.allowable_params]
  ]
  
  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
    
  def self.allowable_params
    FORM_PARAMS
  end
  
  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------
  
  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected 

  def create_funding_amounts
    # Build a set of funding amounts
    current_year = current_fiscal_year_year
    last_year = current_year + (MAX_FORECASTING_YEARS - 1)
    (current_year..last_year).each do |year|
      funding_amount = self.funding_amounts.build({:fy_year => year})
      funding_amount.save
    end    
    
  end
  # Set resonable defaults for a new capital project
  def set_defaults
    self.active ||= true
  end    
      
end
