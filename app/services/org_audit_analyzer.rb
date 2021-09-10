#------------------------------------------------------------------------------
#
# OrgAuditAnalyzer
#
# Contains business logic used in the status page
#
#------------------------------------------------------------------------------


class OrgAuditAnalyzer

  def initialize(org)
    @org = org
  end

	def audit_complete_pcnt
	  report = AuditResultsSummaryReport.new

	  pcnts_passed = []
	  Audit.all.each do |audit|
	    audit_results = report.get_data(audit, [@org.id], Rails.application.config.asset_base_class_name, {disposition_date: nil},{})
	    total_assets = 0
	    passed_assets = 0
	    audit_results[1].each do |row|
	      total_assets += row[2]
	      passed_assets += row[3]
	    end
	    if audit_results[1].length > 0
	      pcnt_passed = ((passed_assets / total_assets.to_f) * 100).truncate
	      pcnts_passed << pcnt_passed
	    end
	  end

	  total_pcnt_passed = pcnts_passed.empty? ? 0 : (pcnts_passed.reduce(:+) / pcnts_passed.size.to_f)
	  total_pcnt_passed = (total_pcnt_passed + 0.5).to_i
	  total_pcnt_passed 
	 end

end