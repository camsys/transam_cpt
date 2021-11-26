class AddFuelTypeToDraftPhase < ActiveRecord::Migration[5.2]
  def change
    add_reference :draft_project_phases, :fuel_type, foreign_key: true, type: :bigint
  end
end
