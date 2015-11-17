#------------------------------------------------------------------------------
#
# FundingPlan
#
# Associates an Activity Line Item with a Funding Source and amount. This is used
# to indicate how the transit agency plans to fund an ALI (and thus a CP).
#
# The amount is the total amount that is being requested. The federal/state/and
# local shares are the portion of the amount that must be matched according to
# the funding source rules.
#
# Example:
#   The funding source is 5307 and the amount is $100,000. The federal share
#   will be $80,000 (80%) and the State Match is $20,000 (20%)
#
#------------------------------------------------------------------------------
class FundingPlan < ActiveRecord::Base

  # Include the object key mixin
  include TransamObjectKey

  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize                  :set_defaults

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------

  # Each funding plan is associated with a single activity line item
  belongs_to  :activity_line_item

  # Each funding plan is associated with a single funding source
  belongs_to  :funding_source

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :activity_line_item,  :presence => :true
  validates :funding_source,      :presence => :true
  validates :amount,              :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}, :allow_nil => true

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------

  #------------------------------------------------------------------------------
  # Constants
  #------------------------------------------------------------------------------

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :activity_line_item_id,
    :funding_source_id,
    :amount
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

  def to_s
    name
  end

  def name
    "#{funding_source.name} $#{amount}" unless amount.nil?
  end

  # Returns the amount of this funding plan that will be met by federal dollars
  def federal_share
    amount * (funding_source.federal_match_required / 100.0)
  end

  # Returns the amount of this funding plan that will be met by state dollars
  def state_share
    amount * (funding_source.state_match_required / 100.0)
  end

  # Returns the amount of this funding plan that will be met by local (organization) dollars
  def local_share
    amount * (funding_source.local_match_required / 100.0)
  end
  def federal_percentage
    100.0 * (federal_share / amount) if amount.to_i > 0
  end
  def state_percentage
    100.0 * (state_share / amount) if amount.to_i > 0
  end
  def local_percentage
    100.0 * (local_share / amount) if amount.to_i > 0
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  # Set resonable defaults for a new capital project
  def set_defaults
    self.amount ||= 0
  end

end
