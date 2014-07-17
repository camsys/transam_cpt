class AddJustificationToAli < ActiveRecord::Migration
  def change
    add_column :activity_line_items, :cost_justification, :text, :after => :estimated_cost
  end
end
