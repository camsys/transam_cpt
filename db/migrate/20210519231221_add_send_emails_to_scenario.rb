class AddSendEmailsToScenario < ActiveRecord::Migration[5.2]
  def change
  	add_column :scenarios, :email_updates, :boolean, default: true 
  end
end
