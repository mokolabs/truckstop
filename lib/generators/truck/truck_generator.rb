class TruckGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  desc "Add legacy database connection to database.yml"
  def add_legacy_database_connection

    connection = <<~YAML
    legacy:
      adapter:
      database:
      encoding:
      username:
      password:
    YAML

    append_to_file 'config/database.yml', "\r#{connection}"
  end

  desc "Add legacy model to app/models/legacy"
  def add_legacy_model
    template "legacy_model.rb.tt", "app/models/legacy/legacy_#{file_name}.rb"
  end

  desc "Add legacy rake task to lib/tasks"
  def add_legacy_rake_task
    template "legacy_task.rake.tt", "lib/tasks/legacy_#{file_name}.rake"
  end

  desc "Add legacy models to autoload_paths"
  def add_legacy_model_loader
    path  = "\r"
    path += "    # Load legacy models\n"
    path += "    config.autoload_paths << Rails.root.join('app/models/legacy')\n"
    path += "\n"

    insert_into_file "config/application.rb", path, :after => "Rails::Application\n"
  end

end
