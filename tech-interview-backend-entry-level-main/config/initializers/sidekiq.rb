require 'sidekiq'
require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq::Scheduler.enabled = true
    Sidekiq::Scheduler.reload_schedule!
  end
  config.schedule = YAML.load_file(File.expand_path('../sidekiq_scheduler.yml', __FILE__)) if File.exists?(File.expand_path('../sidekiq_scheduler.yml', __FILE__))
end

Sidekiq.configure_client do |config|
end
