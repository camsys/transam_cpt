# desc "Explaining what the task does"
# task :transam_cpt do
#   # Task goes here
# end
namespace :transam_cpt do
  desc "Prepare the dummy app for rspec and capybara"
  task :prepare_rspec do
    # Re-exec with RAILS_ENV=test set before Rails/Bundler boot, so dev-only
    # gems (e.g. web-console) never get loaded in the first place.
    if ENV["RAILS_ENV"] != "test"
      exec({ "RAILS_ENV" => "test" }, "bundle", "exec", "rake", "app:transam_cpt:prepare_rspec")
    end

    Rake::Task["environment"].invoke
    %w(db:drop db:create db:schema:load db:migrate db:seed).each do |cmd|
      puts "Running #{cmd} in CPT."
      Rake::Task[cmd].invoke
    end
  end
end