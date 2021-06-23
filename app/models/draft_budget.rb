class DraftBudget < ApplicationRecord

   # Include the object key mixin
  include TransamObjectKey

  # Include the fiscal year mixin
  include FiscalYear

  FORM_PARAMS = [
    :name,
    :amount,
    :shared_across_scenarios,
    :funding_template_id,
    :owner_id,
    :contributor_id,
    :active
  ]

  validates :name, presence: true 
  validates :funding_template_id, presence: true
  validates :amount, presence: true 

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  has_many :draft_budget_allocations
  has_many :draft_funding_requests, through: :draft_budget_allocations
  has_many :draft_project_phases, through: :draft_funding_requests
  has_many :draft_projects, through: :draft_project_phases
  has_many :scenarios, through: :draft_projects
  
  belongs_to :funding_template
  has_one    :funding_source, through: :funding_template
  has_one :funding_source_type, through: :funding_source

  belongs_to :contributor, class_name: "Organization"
  belongs_to :owner, class_name: "Organization"


  #------------------------------------------------------------------------------
  # Placeholders
  #------------------------------------------------------------------------------
  scope :placeholder, -> { where(:default => true) }
  scope :shared, -> { where(:shared_across_scenarios => true) }
  scope :active, -> { where(:active => true)}

  #------------------------------------------------------------------------------
  # Instance Methods
  #------------------------------------------------------------------------------
  def allocated scenario=nil
    if scenario 
      sum = 0
      draft_budget_allocations.each do |dba|
        if dba.scenario == scenario
          sum += dba.amount 
        end
      end
      sum 
    else 
      draft_budget_allocations.pluck(:amount).sum
    end
  end

  def remaining scenario=nil
    if scenario 
      amount - allocated(scenario)
    else
      amount - allocated
    end
  end

  #Federal/State/Local/Agency
  def funding_source_type
    funding_template.funding_source_type 
  end

  def type_and_name
    "#{funding_source_type.try(:name)} #{name}"
  end
  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
  def self.allowable_params
    FORM_PARAMS
  end


end
