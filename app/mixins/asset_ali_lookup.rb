#------------------------------------------------------------------------------
#
# AssetAliLookup
#
# Mixin that adds a methods for mapping between TEAM ALI codes and asset subtypes
#
#------------------------------------------------------------------------------
module AssetAliLookup

  #
  # Returns an asset subtype based on an ALI code
  #
  def asset_subtype_from_ali_code(ali_code)
    # split the ali code on the dots
    elems = ali_code.split('.')
    major_type = elems[0]
    activity = elems[1]
    type = elems[2]

    # Figure out the focus: bus rail or other
    is_bus = false
    is_rail = false
    is_other = false
    if major_type == '11'
      is_bus = true
    elsif major_type == '12'
      is_rail = true
    else
      is_other = true
    end
    
    # No asset subtypes if it is not a bus or rail code
    if is_other
      return nil
    end
    
    # See if we are working with rolling stock or facilities
    if activity[0] == '1'
      # its rolling stock (Vehicle/RailCar/Locomotive)
      return AssetSubtype.where('asset_type_id IN (?) AND ali_code = ?', [Vehicle.new.asset_type_id, RailCar.new.asset_type_id, Locomotive.new.asset_type_id], type).first
    elsif activity[0] == '3'
      # station/stops/terminals (Transit Facilty)
      return AssetSubtype.where('asset_type_id IN (?) AND ali_code = ?', [TransitFacility.new.asset_type_id], type).first
    elsif activity[0] == '4'
      # Admin/maintenance/etc (Support Facilty)
      return AssetSubtype.where('asset_type_id IN (?) AND ali_code = ?', [SupporttFacility.new.asset_type_id], type).first
    else
      # not handled
      return nil
    end
    
  end
end
