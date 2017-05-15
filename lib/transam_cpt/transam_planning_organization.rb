module TransamPlanningOrganization
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
end
