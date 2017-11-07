class AddPinnedReplacementStatusType < ActiveRecord::DataMigration
  def up
    ReplacementStatusType.create!({:active => 1, :name => 'Pinned', :description => 'Asset replacement is pinned and cannot be moved.'}) if ReplacementStatusType.find_by(name: 'Pinned').nil?
  end

  def down
    ReplacementStatusType.find_by(name: 'Pinned').destroy if ReplacementStatusType.find_by(name: 'Pinned')
  end
end