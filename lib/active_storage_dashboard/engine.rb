# frozen_string_literal: true

module ActiveStorageDashboard
  class Engine < ::Rails::Engine
    isolate_namespace ActiveStorageDashboard

    # Ensure URLs are generated correctly by setting defaults
    initializer "active_storage_dashboard.url_options" do |app|
      ActiveStorageDashboard::Engine.routes.default_url_options = app.routes.default_url_options
    end

    config.active_storage_dashboard = ActiveSupport::OrderedOptions.new

    config.before_initialize do
      config.active_storage_dashboard.each do |key, value|
        ActiveStorageDashboard.public_send("#{key}=", value)
      end
    end
  end
end
