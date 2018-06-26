class TemporarilyInactivateCapitalNeedsForecastReport < ActiveRecord::DataMigration
  def up
    Report.find_by(class_name: 'CapitalNeedsForecast').update!(active: false)
  end

  def down
    Report.find_by(class_name: 'CapitalNeedsForecast').update!(active: true)
  end
end