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

    asset.record_disposition
  end

  def prepare
    Rails.logger.debug "Executing AssetDispositionUpdateJob at #{Time.now.to_s} for Asset #{object_key}"    
  end
  
end