class CapitalPlanModule < ActiveRecord::Base

  #------------------------------------------------------------------------------
  # Behaviors
  #------------------------------------------------------------------------------
  # Include the object key mixin
  include TransamObjectKey

  belongs_to :capital_plan_module_type

  belongs_to :capital_plan

  has_many :capital_plan_actions, :dependent => :destroy


  validates :capital_plan_module_type, :presence => true
  validates :capital_plan, :presence => true

  default_scope { order(:sequence) }

  def completed?
    completed_at.present?
  end

  def is_allowed?
    capital_plan.capital_plan_modules.where('completed_at IS NULL AND sequence < ?', sequence).count == 0 && !(capital_plan_actions.pluck(:completed_at).include? nil) && completed_at.nil?
  end

  def is_undo_allowed?
    (next_module.nil? || next_module.capital_plan_actions.pluck(:completed_at).uniq == [nil]) && (capital_plan_actions.pluck(:completed_at).include? nil) && completed_at.present?
  end

  def prev_module
    capital_plan.capital_plan_modules.where('sequence < ?', self.sequence).order(:sequence).last
  end

  def next_module
    capital_plan.capital_plan_modules.where('sequence > ?', self.sequence).order(:sequence).first
  end

end
