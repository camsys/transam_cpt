class AddReviewerOrgToScenario < ActiveRecord::Migration[5.2]
  def change
  	add_reference :scenarios, :reviewer_organization, foreign_key: { to_table: :organizations }, type: :integer
  end
end
