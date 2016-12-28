module TransamPlanningFilters
  #------------------------------------------------------------------------------
  #
  # Plannable
  #
  # Injects methods and associations for associating transit assets with capital planning
  # activities
  #
  # Model
  #
  #   The following properties are injected into the Asset Model
  #
  #     has_and_belongs_to_many    :activity_line_items,  :foreign_key => 'asset_id'
  #
  #------------------------------------------------------------------------------
  extend ActiveSupport::Concern

  included do

    # ----------------------------------------------------
    # Call Backs
    # ----------------------------------------------------


    # ----------------------------------------------------
    # Associations
    # ----------------------------------------------------

    # belongs to 0 or 1 activity_line_items
    # Every user has 0 or 1 user organization filter that they are using and a list that they own
    belongs_to :user_activity_line_item_filter
    has_and_belongs_to_many :user_activity_line_item_filters, :join_table => 'users_user_activity_line_item_filters'

    # ----------------------------------------------------
    # Validations
    # ----------------------------------------------------


  end

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  module ClassMethods

  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------


end
