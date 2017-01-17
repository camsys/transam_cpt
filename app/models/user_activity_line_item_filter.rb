class UserActivityLineItemFilter < ActiveRecord::Base

  # Include the unique key mixin
  include TransamObjectKey

  # Callbacks
  after_initialize :set_defaults

  belongs_to :resource, :polymorphic => true

  # Each filter is created by someone usually the owner but sometimes the system user (could be extended to sharing filters)
  belongs_to :creator, :class_name => "User", :foreign_key => :created_by_user_id

  # Each filter can have a list of organizations that are included
  has_and_belongs_to_many :organizations, :join_table => 'user_activity_line_item_filters_organizations'

  has_and_belongs_to_many :users, :join_table => 'users_user_activity_line_item_filters'

  validates   :name,          :presence => :true
  validates   :description,   :presence => :true

  # Allow selection of active instances
  scope :active, -> { where(:active => true) }

  # Named Scopes
  scope :system_filters, -> { where('created_by_user_id = ? AND active = ?', 1, 1 ) }
  scope :other_filters, -> { where('created_by_user_id > ? AND active = ?', 1, 1 ) }

  # List of allowable form param hash keys
  FORM_PARAMS = [
      :name,
      :description,
      :capital_project_type_id,
      :sogr_type,
      :team_ali_code_id,
      :asset_type_id,
      :asset_subtype_id,
      :in_backlog
  ]

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  def self.allowable_params
    FORM_PARAMS
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  # Returns true if this is a system filter
  def system_filter?
    UserOrganizationFilter.system_filters.include? self
  end

  def shared
    if self.resource.nil? && self.users.count == 1
      'No One'
    elsif self.resource.present? && self.users.count > 1
      self.resource.short_name
    elsif self.resource.nil? && self.users.count > 1
      'All Organizations'
    else
      'Unknown'
    end
  end

  def can_update? user
    !self.system_filter? && (self.users.include? user)
  end

  def can_destroy? user
    !self.system_filter? && (self.users.include? user) && self != user.user_organization_filter
  end

  def to_s
    self.name
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------

  protected

  private
  # Set resonable defaults for a new filter
  def set_defaults
    self.active = self.active.nil? ? true : self.active
  end


end
