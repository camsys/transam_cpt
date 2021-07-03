class MilestoneType < ActiveRecord::Base

  # Active scope -- always use this scope in forms
  scope :active, -> { where(active: true) }

  #milestone types associated with vehicle delivery
  scope :vehicle_delivery_milestones, -> { where(:active => true) }

  #milestone types associated with other projects
  scope :other_project_milestones, -> { where(:active => true, :is_vehicle_delivery => false) }

  def to_s
    name
  end

   #------------------------------------------------------------------------------
  # DotGrants Export
  #------------------------------------------------------------------------------
  def dotgrants_json
    { name: name }
  end

end
