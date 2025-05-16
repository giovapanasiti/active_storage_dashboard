# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "active_storage_dashboard"
  spec.version       = "0.1.1"
  spec.authors       = ["Giovanni Panasiti"]
  spec.email         = ["giova.panasiti@gmail.com"]

  spec.summary       = "A dashboard for Active Storage in Rails applications"
  spec.description   = "A mountable Rails engine that provides a dashboard to view Active Storage data"
  spec.homepage      = "https://github.com/giovapanasiti/active_storage_dashboard"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 5.2.0"
end 