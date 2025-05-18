# frozen_string_literal: true
require "rails/railtie"

require "active_storage_dashboard/version"
require "active_storage_dashboard/engine"

require "active_storage_dashboard/orphan_purger"
require "active_storage_dashboard/analyzer"
require "active_storage_dashboard/variant_regenerator"

module ActiveStorageDashboard
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("tasks/active_storage_dashboard_tasks.rake", __dir__)
    end
  end
end 

