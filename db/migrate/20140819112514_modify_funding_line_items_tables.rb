class ModifyFundingLineItemsTables < ActiveRecord::Migration
  def change
    rename_column :funding_line_items, :federal_project_number, :project_number
    add_column    :funding_line_items, :spent, :integer, :after => :amount
  end
end
