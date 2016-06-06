namespace :transam do
  desc "Build SOGR projects from scratch"
  task :build_sogr_projects, [:org_short_name] => [:environment] do |t, args|
    org = Organization.find_by(short_name: args[:org_short_name])
    orgs = org.nil? ? Organization.all : [org]
    CapitalProject.where(organization: orgs).destroy_all

    orgs.each do |o|
      org = Organization.get_typed_organization(o)

      builder = CapitalProjectBuilder.new
      num_created = builder.build(org) # uses default options

      puts "#{num_created} SOGR capital projects were added to #{org.short_name}'s capital needs list."
    end
  end
end
