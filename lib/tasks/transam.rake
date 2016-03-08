namespace :transam do
  desc "Build SOGR projects from scratch"
  task build_sogr_projects: :environment do
    CapitalProject.destroy_all

    Organization.all.each do |o|
      org = Organization.get_typed_organization(o)

      builder = CapitalProjectBuilder.new
      num_created = builder.build(org) # uses default options

      puts "#{num_created} SOGR capital projects were added to #{org.short_name}'s capital needs list."
    end
  end
end
