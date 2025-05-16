# Active Storage Dashboard

A Rails engine that provides a dashboard for monitoring and inspecting Active Storage data in your Rails application.

## Features

- Overview of Active Storage usage statistics
- Browse and inspect blobs, attachments and variant records
- View metadata, file details, and relationships
- No external dependencies (vanilla JavaScript and CSS)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_storage_dashboard'
```

And then execute:

```bash
$ bundle
```

## Usage

Mount the engine in your `config/routes.rb` file:

```ruby
Rails.application.routes.draw do
  # IMPORTANT: Make sure the mount path does not contain any special characters
  # Use a simple path like '/active-storage-dashboard' or '/storage-dashboard'
  # This is crucial for proper URL generation
  mount ActiveStorageDashboard::Engine, at: "/active-storage-dashboard"
end
```

Then visit `/active-storage-dashboard` in your browser.

### File Downloads

The dashboard provides direct file download capabilities from both the list and detail views.

## Security Considerations

This dashboard provides access to all Active Storage data. Consider adding authentication before using in production:

```ruby
# config/routes.rb
authenticate :user, -> (user) { user.admin? } do
  mount ActiveStorageDashboard::Engine, at: "/active-storage-dashboard"
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT). 