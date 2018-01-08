class UpdateMilestoneTypeNames < ActiveRecord::DataMigration
  def up
    MilestoneType.find_by(name: 'Contract Awarded').update!(name: 'Contract Award') if MilestoneType.find_by(name: 'Contract Awarded')
    MilestoneType.find_by(name: 'Contract Completed').update!(name: 'Contract Complete') if MilestoneType.find_by(name: 'Contract Completed')
  end
end