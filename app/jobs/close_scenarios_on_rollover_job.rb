#------------------------------------------------------------------------------
#
# CloseScenariosOnRolloverJob
#
# Build SOGR projects
#
#------------------------------------------------------------------------------
class CloseScenariosOnRolloverJob < Job

  def run
    scenarios = Scenario.where.not(state: ['approved', 'cancelled'])
    @logger.info "Closing #{scenarios.count} scenarios"
    scenarios.each do |s|
      # Possible race condition here
      s.cancel unless s.state == 'approved'
    end
  end

  def prepare
    @logger = Delayed::Worker.logger || Rails.logger
    @logger.info "Executing CloseScenariosOnRolloverJob at #{Time.now.to_s}"
  end
end
