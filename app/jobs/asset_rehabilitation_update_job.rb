#------------------------------------------------------------------------------
#
# AssetRehabilitationUpdateJob
#
# Updates an assets rehabilitation ststus
#
#------------------------------------------------------------------------------
class AssetRehabilitationUpdateJob < AbstractAssetUpdateJob

  def requires_sogr_update?
    false # manually call it in job so can perform update rehab actions in correct order
  end

  def execute_job(asset)
    asset.update_rehabilitation

    asset.update_sogr

    update_sched_replacement_yr = false

    if asset.rehabilitation_updates.empty?
      update_sched_replacement_yr = true
    else
      last_rehab = asset.rehabilitation_updates.last
      if last_rehab.extended_useful_life_months > 0 || last_rehab.extended_useful_life_miles > 0
        update_sched_replacement_yr = true
      end
    end

    if update_sched_replacement_yr
      asset.update(scheduled_replacement_year: asset.policy_replacement_year)

      typed_asset = Asset.get_typed_asset(asset)
      ali = typed_asset.activity_line_items.joins(:capital_project).where(capital_projects: {sogr: true, notional: false}).first

      service = CapitalProjectBuilder.new
      service.update_asset_schedule(asset)
      asset.reload

      # update the original ALI's estimated cost for its assets
      updated_ali = ActivityLineItem.find_by(id: ali.id)
      if updated_ali.present?
        updated_ali.update_estimated_cost
        Rails.logger.debug("NEW COST::: #{updated_ali.estimated_cost}")
      end
    end

  end

  def prepare
    Rails.logger.debug "Executing AssetRehabilitationUpdateJob at #{Time.now.to_s} for Asset #{object_key}"
  end

end
