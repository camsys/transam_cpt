module TransamPlanningOrganization

  PLAN_TYPE = 1


  #------------------------------------------------------------------------------
  #
  # PlanningOrganization
  #
  # Injects methods and associations for organizations who perform capital planning
  #
  # Model
  #
  #   The following properties are injected into the Asset Model
  #
  #     has_many    :capital_projects
  #     has_many    :budget_amounts
  #
  #------------------------------------------------------------------------------
  extend ActiveSupport::Concern

  included do

    # ----------------------------------------------------
    # Call Backs
    # ----------------------------------------------------

    after_create :set_capital_plan_type

    # ----------------------------------------------------
    # Associations
    # ----------------------------------------------------

    # Each Transit Agency has one or more capital projects. The capital projects will be removed if the org is removed
    has_many    :capital_projects,  -> { order(:fy_year) }, :foreign_key => :organization_id,  :dependent => :destroy

    has_many :capital_plans, :foreign_key => :organization_id,  :dependent => :destroy
    belongs_to :capital_plan_type

    # ----------------------------------------------------
    # Validations
    # ----------------------------------------------------


  end

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  module ClassMethods

  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  def has_sogr_projects?
    (capital_projects.sogr.count > 0)
  end

  private

  def set_capital_plan_type
    self.update_attributes(capital_plan_type_id: PLAN_TYPE)
  end
end
