#------------------------------------------------------------------------------
#
# CapitalProject
#
# Represents a capital project in TransAM. Each capital project is composed of
# one or more ActivityLineItems and is associated with a particular fiscal year.
#
#------------------------------------------------------------------------------
class CapitalProject < ActiveRecord::Base
    
  # Include the unique key mixin
  include UniqueKey

  #------------------------------------------------------------------------------
  # Overrides
  #------------------------------------------------------------------------------
  
  #require rails to use the asset key as the restful parameter. All URLS will be of the form
  # /capital_project/{object_key}/...
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
  # Every capital project belongs to an organization
  belongs_to  :organization

  # Has a single project status
  belongs_to  :capital_project_status_type

  # Has a single TEAM scope
  belongs_to  :team_scope_code

  # Has a single TEAM category, eg Expansion, Rehabilitation, etc
  belongs_to  :team_category

  # Has many MPMS projects. These will be removed if the project is removed
  has_many    :mpms_projects, :dependent => :destroy
    
  # Has 0 or more activity line items. These will be removed if the project is removed.
  has_many    :activity_line_items, :dependent => :destroy

  # Has 0 or more documents. Using a polymorphic association. These will be removed if the project is removed
  has_many    :documents,   :as => :documentable, :dependent => :destroy

  # Has 0 or more comments. Using a polymorphic association, These will be removed if the project is removed
  has_many    :comments,    :as => :commentable,  :dependent => :destroy

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => true, :uniqueness => true
  validates :organization_id,                   :presence => true
  validates :team_scope_code_id,                :presence => true
  validates :team_category_id,                  :presence => true
  validates :capital_project_status_type_id,    :presence => true
  #validates :project_number,                    :presence => true, :uniqueness => true
  validates :title,                             :presence => true
  validates :description,                       :presence => true
  validates :justification,                     :presence => true

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  
  # default scope
  default_scope { where(:active => true) }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    #:project_number, 
    :organization_id,
    :team_scope_code_id,
    :team_category_id,
    :capital_project_status_type_id, 
    :title,
    :description,
    :justification,
    :emergency,
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

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected 

  # Set resonable defaults for a new capital project
  def set_defaults
    self.active ||= true
    self.emergency ||= false
    self.capital_project_status_type_id ||= 1
  end    
      
end
