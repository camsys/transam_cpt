#------------------------------------------------------------------------------
#
# ActivityLineItem
#
# Represents a group of self-similar assets that the organization is requesting
# funding for as part of a larger capital project. Each ALI is associated with
# a single TEAM ALI code eg 11.12.01 that indicates the type of fundiung being
# applied for.
#
#------------------------------------------------------------------------------
class ActivityLineItem < ActiveRecord::Base
    
  # Include the unique key mixin
  include UniqueKey
  # Include the numeric sanitizers mixin
  include NumericSanitizers

  #------------------------------------------------------------------------------
  # Overrides
  #------------------------------------------------------------------------------
  
  #require rails to use the asset key as the restful parameter. All URLS will be of the form
  # /activity_line_item/{object_key}/...
  def to_param
    object_key
  end
  
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize :set_defaults
  
  # Always generate a unique object key before saving to the database
  before_validation(:on => :create) do
    generate_unique_key(:object_key)
  end
  
  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  
  # Every ali belongs to a capital project
  belongs_to  :capital_project

  # Every ALI has a single TEAM sub catagory code
  belongs_to  :team_sub_category
  
  # Has 0 or more assets
  has_many    :assets
    
  # Has 0 or more milestones
  has_many    :milestones
  
  # Has 0 or more comments. Using a polynmorphic association
  has_many    :comments,  :as => :commentable

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => true, :uniqueness => true
  validates :capital_project_id,                :presence => true
  validates :name,                              :presence => true
  validates :team_sub_category_id,              :presence => true


  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  
  # default scope
  default_scope { where(:active => true) }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    :capital_project_id, 
    :name,
    :team_sub_category_id, 
    :active    
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

  def to_s
    name
  end
  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected 


  # Set resonable defaults for a new activity line item
  def set_defaults
    self.active ||= true
  end    
      
end
