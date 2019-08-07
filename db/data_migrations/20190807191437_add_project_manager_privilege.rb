class AddProjectManagerPrivilege < ActiveRecord::DataMigration
  def up
    Role.create!(name: 'project_manager', show_in_user_mgmt: true, privilege: true, label: 'Project Planning Lead')

    User.joins(:roles).where(roles: {name: ['transit_manager', 'manager']}).each do |u|
      UsersRole.find_or_create_by!(user: u, role: Role.find_by(name: 'project_manager')) do |r|
        r.active = true
      end
    end
  end

  def down
    UsersRole.where(role: Role.find_by(name: 'project_manager')).destroy_all

    Role.find_by(name: 'project_manager').destroy
  end
end