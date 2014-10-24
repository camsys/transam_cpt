puts "factory_girl.rb"
RSpec.configure do |config|
  puts "config in factory_girl.rb"
  # additional factory_girl configuration
  
  # DatabaseCleaner.strategy = :truncation, {:only => %w[assets asset_events organizations]}
  DatabaseCleaner.strategy = :truncation
  config.before(:suite) do
    begin
      puts "config.before :suite"
      DatabaseCleaner.start
      #FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
  end
end
