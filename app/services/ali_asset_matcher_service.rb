#------------------------------------------------------------------------------
#
# AliAssetMatcherService
#
# Matches an Activity Line Item to assets that could be added to the ALI
#
# The service returns an array of Asset that are suitable for adding to an
# the given project
#
#------------------------------------------------------------------------------
class AliAssetMatcherService

  #------------------------------------------------------------------------------
  #
  # Match
  #
  # Single entry point. User passes in a an activity line item. The system get
  # the rest of what it needs from the ALI and its relationships
  #
  #------------------------------------------------------------------------------
  def match(ali, options = {})

    a = []
    if ali.nil?
      Rails.logger.info "ALI cannot be nil."
      return a
    end

    # Get set up
    capital_project = ali.capital_project
    if capital_project.nil?
      Rails.logger.info "ALI is not associated with a capital project."
      return a
    end

    organization = Organization.get_typed_organization(capital_project.organization)
    if organization.nil?
      Rails.logger.info "ALI is not associated with an organization."
      return a
    end

    Rails.logger.info "Evaluating assets for ALI #{ali}."

    # The Policy Item class contain the ALI codes for replacement and rehabilitation
    # project codes. We need to simple query the policy items and return the list
    # or matching asset subtypes, find those assets which match the replacement or
    # rehabilitation criteria for this ALI and remove any that are already in an
    # ALI

    # Find matching Policy Items
    if ali.team_ali_code.replacement_code?
      rules = PolicyItem.where(:replacement_ali_code => ali.team_ali_code.code)
    elsif ali.team_ali_code.rehabilitation_code?
      rules = PolicyItem.where(:rehabilitation_ali_code => ali.team_ali_code.code)
    else
      rules = []
    end

     # Start to set up the asset query.
    conditions  = []
    values      = []

    # must belong to the org that owns the capital project
    conditions << 'organization_id = ?'
    values << capital_project.organization.id

    # cant already be disposed
    conditions << 'disposition_date IS NULL'

    # cant be scheduled for disposition
    conditions << 'scheduled_disposition_year IS NULL'

    # can't already be associated with the ALI
    unless ali.assets.empty?
      conditions << 'id NOT IN (?)'
      values << ali.asset_ids
    end

    # Get the matching asset subtypes from the rules we matched
    asset_subtype_ids = []
    rules.each {|x| asset_subtype_ids << x.asset_subtype_id}

    # If there are no matching codes there is nothing else to do
    if asset_subtype_ids.empty?
      Rails.logger.info "There are no matching asset subtypes for code #{ali.team_ali_code.code}."
      return a
    end
    # add to our query
    conditions << 'asset_subtype_id IN (?)'
    values << asset_subtype_ids.uniq

    # Check for replacement/rebuild/rehab years
    if ali.team_ali_code.replacement_code?
      conditions << 'scheduled_replacement_year = ?'
      values << capital_project.fy_year
    elsif ali.team_ali_code.rehabilitation_code?
      conditions << 'scheduled_rehabilitation_year = ?'
      values << capital_project.fy_year
    end

    Rails.logger.debug conditions.inspect
    Rails.logger.debug values.inspect

    a = Asset.where(conditions.join(' AND '), *values).order(:asset_type_id, :asset_subtype_id)

    Rails.logger.debug "Found #{a.size} mathcing assets."

    # return this list
    a
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  #------------------------------------------------------------------------------
  #
  # Private Methods
  #
  #------------------------------------------------------------------------------
  private

end
