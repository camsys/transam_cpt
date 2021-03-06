#------------------------------------------------------------------------------
#
# AssetUpdateJob
#
# Performs all updates on an asset
#
#------------------------------------------------------------------------------
class PolicyDistributerJob < Job

  attr_accessor :policy_distributer_proxy
  attr_accessor :creator

  def run

    Policy.where(parent_id: policy_distributer_proxy.policy.id).each do |p|
      p.policy_asset_subtype_rules.each do |subtype_rule|
        parent_rules = subtype_rule.min_allowable_policy_values

        subtype_rule.update(subtype_rule.attributes.slice(*parent_rules.stringify_keys.keys).merge(parent_rules.stringify_keys){|key, oldval, newval| [oldval, newval].max})

        mileage_rules = subtype_rule.min_allowable_mileages

        subtype_rule.update(subtype_rule.attributes.slice(*mileage_rules.stringify_keys.keys).merge(mileage_rules.stringify_keys){|key, oldval, newval| [oldval, newval].max})
      end

      if policy_distributer_proxy.apply_policies.to_i == 1
        # Rip through the organizations assets, creating a job for each type requested
        assets = Asset.operational.where(organization_id: p.organization_id)
        assets.find_each do |a|
          typed_asset = Asset.get_typed_asset(a)
          typed_asset.update_methods.each do |m|
            begin
              typed_asset.send(m, false) #dont save until all updates have run
            rescue Exception => e
              Rails.logger.warn e.message
            end
          end
          typed_asset.save
        end
      end

      if policy_distributer_proxy.build_projects.to_i == 1
        builder = CapitalProjectBuilder.new
        num_created = builder.build(p.organization)
      end
    end



    event_url = Rails.application.routes.url_helpers.policy_path policy_distributer_proxy.policy
    msg = 'Parent policy distributed.'
    msg += ' Assets updated for new policy.' if policy_distributer_proxy.apply_policies.to_i == 1
    msg += ' SOGR projects built.' if policy_distributer_proxy.build_projects.to_i == 1

    # Add a row into the activity table
    ActivityLog.create({:organization_id =>policy_distributer_proxy.policy.organization_id, :user_id => creator.id, :item_type => "Policy Distributor", :activity => msg, :activity_time => Time.now})

    policy_notification = Notification.create(text: msg, link: event_url, notifiable_type: 'Organization', notifiable_id: policy_distributer_proxy.policy.organization_id)
    UserNotification.create(user: creator, notification: policy_notification)

  end

  def prepare
    Rails.logger.debug "Executing PolicyDistributerJob at #{Time.now.to_s} for all assets"
  end

  def check
    raise ArgumentError, "policy distributer proxy can't be blank " if policy_distributer_proxy.nil?
    raise ArgumentError, "creator can't be blank " if creator.nil?
  end

  def initialize(policy_distributer_proxy, creator)
    super
    self.policy_distributer_proxy = policy_distributer_proxy
    self.creator = creator
  end

end
