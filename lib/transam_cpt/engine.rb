module TransamCpt
  class Engine < ::Rails::Engine
    # Add a load path for this specific Engine
    config.autoload_paths += %W(#{Rails.root}/app/calculators)
    config.autoload_paths += %W(#{Rails.root}/app/jobs)
    config.autoload_paths += %W(#{Rails.root}/app/reports)
    config.autoload_paths += %W(#{Rails.root}/app/searches)
    config.autoload_paths += %W(#{Rails.root}/app/services)

    # Append migrations from the engine into the main app
    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
        config.paths.add "db/data_migrations"
        config.paths["db/data_migrations"].expanded.each do |expanded_path|
          app.config.paths["db/data_migrations"] << expanded_path
        end
      end
    end

    config.to_prepare do
      SystemConfig.transam_module_names.each do |mod|
        Dir.glob("transam_#{mod}".camelize.constantize::Engine.root + "app/decorators/**/*_decorator*.rb").each do |c|
          require_dependency(c)
        end
      end
    end

  end

end
