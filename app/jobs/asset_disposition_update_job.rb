#------------------------------------------------------------------------------
#
# AssetDispositionUpdateJob 
# (overrides the job in transam_core in order to remove the asset from ALIs before the disposition)
#
# Records that an asset has been disposed.
#
#------------------------------------------------------------------------------
class AssetDispositionUpdateJob < AbstractAssetUpdateJob
  
  
  def execute_job(asset)  
    # remove the asset from ALIs if going to dispose it
    asset = Asset.get_typed_asset(asset)
    if asset.respond_to?(:activity_line_items) && !asset.disposition_updates.empty?   
      asset.activity_line_items.each do |ali|
        ali.assets.destroy(asset) # trigger ALI after_update_callback
      end
    end

    asset_event_type = AssetEventType.where(:class_name => 'DispositionUpdateEvent').first
    asset_event = AssetEvent.where(:asset_id => asset.id, :asset_event_type_id => asset_event_type.id).last
    disposition_type = DispositionType.where(:id => asset_event.disposition_type_id).first
    asset_already_transferred = asset.disposed disposition_type

    asset.record_disposition
    if(!asset_already_transferred && asset_event.disposition_type_id == 2)
      new_asset = asset.transfer asset_event.organization_id
      send_asset_transferred_message new_asset
    end

    if (asset.respond_to? :general_ledger_accounts) && GrantPurchase.sourceable_type == 'Grant' && asset.general_ledger_accounts.count > 0
      disposal_account = ChartOfAccount.find_by(organization_id: asset.organization_id).general_ledger_accounts.find_by(general_ledger_account_subtype: GeneralLedgerAccountSubtype.find_by(name: 'Disposal Account'))

      asset.grant_purchases.each do |grant_purchase|
        amount = (asset.purchase_cost-asset.book_value) * grant_purchase.pcnt_purchase_cost / 100.0

        asset.general_ledger_accounts.accumulated_depreciation_accounts.find_by(grant_id: grant_purchase.sourceable_id).general_ledger_account_entries.create!(sourceable_type: 'Asset', sourceable_id: asset.id, description: "#{asset.organization}: #{asset.to_s} Disposal #{asset.disposition_date}", amount: amount)
      end

      if asset.book_value > 0
        disposal_account.general_ledger_account_entries.create!(sourceable_type: 'Asset', sourceable_id: asset.id, description: "#{asset.organization}: #{asset.to_s} Disposal #{asset.disposition_date}", amount: asset.book_value)
      end

      asset.general_ledger_account.general_ledger_account_entries.create!(sourceable_type: 'Asset', sourceable_id: asset.id, description: "#{asset.organization}: #{asset.to_s} Disposal #{asset.disposition_date}", amount: -asset.purchase_cost)

      disposition_event = asset.disposition_updates.last
      if disposition_event.sales_proceeds > 0
        disposal_account.general_ledger_account_entries.create!(sourceable_type: 'Asset', sourceable_id: asset.id, description: "#{asset.organization}: #{asset.to_s} Disposal #{asset.disposition_date}", amount: -disposition_event.sales_proceeds)
      end
    end
  end

  def prepare
    Rails.logger.debug "Executing AssetDispositionUpdateJob at #{Time.now.to_s} for Asset #{object_key}"    
  end

  def send_asset_transferred_message asset

    transit_managers = get_users_for_organization asset.organization

    event_url = Rails.application.routes.url_helpers.edit_inventory_path asset

    transfer_notification = Notification.create(text: "A new asset has been transferred to you. Please update the asset.", link: event_url, notifiable_type: 'Organization', notifiable_id: asset.organization_id )

    transit_managers.each do |usr|
      UserNotification.create(notification: transfer_notification, user: usr)
    end

  end

  # TODO there is probably a better way
  def get_users_for_organization organization
    user_role = Role.find_by(:name => 'transit_manager')

    unless user_role.nil?
      users = organization.users_with_role user_role.name
    end

    return users || []
  end

end