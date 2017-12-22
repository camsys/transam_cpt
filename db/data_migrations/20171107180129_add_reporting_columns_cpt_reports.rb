class AddReportingColumnsCptReports < ActiveRecord::DataMigration
  def up
    Report.find_by(name: 'Capital Needs Forecast').update!(printable: true, exportable: true) if Report.find_by(name: 'Capital Needs Forecast')
    Report.find_by(name: 'Unconstrained Capital Needs Forecast').update!(printable: true, exportable: true) if Report.find_by(name: 'Unconstrained Capital Needs Forecast')
  end
end