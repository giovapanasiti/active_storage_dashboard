# 🚀 Active Storage Dashboard

A beautiful Rails engine that provides a sleek, modern dashboard for monitoring and inspecting Active Storage data in your Rails application.

![Active Storage Dashboard Screenshot](https://github.com/giovapanasiti/active_storage_dashboard/blob/main/screenshots/dashboard.png)

## 🚨 Security advisory: CVE-2026-66066 (Active Storage / libvips)

**CVE-2026-66066** allows an unauthenticated attacker who can upload a crafted file to read arbitrary
files from your server, including the process environment — which usually holds `secret_key_base`,
your master key, and credentials for your database and storage provider. That can escalate to remote
code execution.

**This gem does not contain the vulnerability and cannot fix it.** The flaw is in Active Storage's
use of libvips, and the fix is to upgrade `activestorage` (to `7.2.3.2`, `8.0.5.1`, `8.1.3.1` or
later) with libvips `>= 8.13`.

What matters here is that **this dashboard triggers the vulnerable code paths in bulk**, so it can
fire an exploit that would otherwise sit dormant:

| Feature | Call | Why it matters |
|---|---|---|
| `rails active_storage:dashboard:reanalyze` | `blob.analyze` | Hands the raw uploaded bytes straight to `Vips::Image.new_from_file`. The only gate is the attacker-supplied content type. |
| `rails active_storage:dashboard:regenerate_variants` | `representation(...).processed` | Reprocesses every stored variant through libvips. |
| Blob/attachment previews in the UI | `blob.preview(...).processed` | Runs the previewer chain over untrusted files while you browse. |

Two things make this worse than an ordinary application code path. These operations run over **every
blob**, so an attacker does not need to lure anyone into viewing their file — they just wait for
maintenance. And the rake tasks typically run **on a production host with the full deployment
environment loaded**, which is exactly the environment the advisory says gets exfiltrated.

Note that an application can be affected even if it never displays image variants; image *analysis*
alone is enough.

### What to do

1. **Do not run `active_storage:dashboard:reanalyze`, `:regenerate_variants`, or `:all`** until you
   have upgraded. These are the highest-risk paths in this gem.
2. Upgrade `activestorage` and ensure libvips `>= 8.13`.
3. **Rotate every secret readable by the application process** — `secret_key_base`, your master key
   and everything in `credentials.yml.enc`, storage service keys, database credentials, and any
   third-party tokens. Upgrading closes the hole but does not un-leak anything already taken.
4. If you cannot upgrade yet but have libvips `>= 8.13`, set `VIPS_BLOCK_UNTRUSTED=1` in the
   application's environment as an interim mitigation.

The dashboard shows a **Processing Safety** panel reporting the state of your own environment, and
warns on every page while it detects an unsafe configuration.

## ✨ Features

- 📊 Overview of Active Storage usage statistics
- 🔍 Browse and inspect blobs, attachments and variant records
- 📝 View metadata, file details, and relationships
- 🎨 Modern, responsive UI with animations
- 🚫 No external dependencies (vanilla JavaScript and CSS)

## 📥 Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_storage_dashboard'
```

And then execute:

```bash
$ bundle
```

## 🔧 Usage

Mount the engine in your `config/routes.rb` file:

```ruby
Rails.application.routes.draw do
  # IMPORTANT: Make sure the mount path does not contain any special characters
  # Use a simple path like '/active-storage-dashboard' or '/storage-dashboard'
  # This is crucial for proper URL generation
  mount ActiveStorageDashboard::Engine, at: "/active-storage-dashboard"
end
```

Then visit `/active-storage-dashboard` in your browser to see the beautiful dashboard.

### 📁 File Downloads

The dashboard provides direct file download capabilities from both the list and detail views. Simply click on the download button to get your files.

### Tasks

The dashboard includes a task to remove unused blobs and attachments. 

You can run this task from the command line:

```bash
$ rails active_storage:dashboard:purge_orphans
```
Re-analyze blobs that are not yet analyzed
```bash
$ rails active_storage:dashboard:reanalyze
```

Regenerate missing or outdated variants
```bash
$ rails active_storage:dashboard:regenerate_variants
```



### 📸 Screenshots

<details>
  <summary>Click to see more screenshots</summary>

  #### Dashboard Overview
  ![Dashboard Overview](https://github.com/giovapanasiti/active_storage_dashboard/blob/main/screenshots/dashboard.png)

  #### Blob Details
  ![Blob Details](https://github.com/giovapanasiti/active_storage_dashboard/blob/main/screenshots/blob-details.png)

  #### Files Gallery
  ![Files Gallery](https://github.com/giovapanasiti/active_storage_dashboard/blob/main/screenshots/files-gallery.png)

</details>

## 🔒 Security Considerations

This dashboard provides access to all Active Storage data. Consider adding authentication before using in production:

```ruby
# config/routes.rb
authenticate :user, -> (user) { user.admin? } do
  mount ActiveStorageDashboard::Engine, at: "/active-storage-dashboard"
end
```

or with devise:

```ruby
constraints lambda { |req| req.session[:user_id].present? || (req.env['warden'] && req.env['warden'].user(:user)) } do
  mount ActiveStorageDashboard::Engine, at: "/active-storage-dashboard"
end
```

Or, in your environment config or `application.rb`:
```ruby
config.active_storage_dashboard.base_controller_class = "AdminController"
```


## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/giovapanasiti/active_storage_dashboard.

## 📝 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
