module TransamPlannable
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

     # Clean up any HABTM associations before the asset is destroyed
    before_destroy { activity_line_items.clear }

    # ----------------------------------------------------
    # Associations
    # ----------------------------------------------------

    # belongs to 0 or 1 activity_line_items
    has_and_belongs_to_many    :activity_line_items,  :foreign_key => 'asset_id'

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
