module TransamCpt
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
  
      # Each Transit Agency has forcast budget amounts for each fiscal year. The budget amounts will be removed if the org is removed
      has_many    :budget_amounts,  :foreign_key => :organization_id,  :dependent => :destroy   

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
  
    # Returns an array of amounts for the selected funding source over the planning
    # period
    def budget(funding_source)
      
      if funding_source.nil?
        return []
      end
      
      a = []
      (current_planning_year_year..last_fiscal_year_year).each do |year|
        budget = budget_amounts.where(:funding_source => funding_source, :fy_year => year).first
        if budget
          a << budget
        else
          a << 0
        end
      end
      
      a
      
    end
  end
end
