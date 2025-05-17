# Changelog

All notable changes to Active Storage Dashboard will be documented in this file.

## [0.1.5] - 2025-05-17
### Added
- Footer with love message and GitHub link to dashboard
- Filtering functionality for attachments and blobs with enhanced UI styles
- Purgable blobs statistic to dashboard with corresponding UI updates

### Changed
- Truncate blob filename display to 40 characters for improved UI consistency
- Refactored filename display for better UI consistency and truncation handling across attachments and blobs

## [0.1.4] - 2025-05-16
### Added
- Filename truncation and title attributes for better UI in attachments and blobs
- Locale to time_ago_in_words in latest activity section (PR #3 from david-uhlig)

### Changed
- Increased filename truncation length to 100 characters for better visibility
- Enhanced progress bar animation by tracking already animated bars (Fixes #2)
- Added .gem to .gitignore

## [0.1.3] - 2025-05-16
### Fixed
- Updated pagination links to use request path for improved routing
- Updated active_storage_dashboard pagination links to use correct route

### Changed
- Removed placeholder for allowed_push_host in gemspec

## [0.1.2] - 2025-05-16
### Fixed
- Updated active_storage_dashboard pagination links to use correct route

## [0.1.1] - 2025-05-16
### Added
- Timeline data loading and error handling for blob statistics
- Enhanced download functionality to support disposition parameter for attachments and blobs

### Changed
- Updated README with modern UI description, feature highlights, and additional screenshots
- Improved media preview in the UI

### Fixed
- Updated copyright information
- Updated README to use correct screenshot URLs for better accessibility
- Removed placeholder note for screenshot in README

## [0.1.0] - 2025-05-16
### Added
- Initial release of Active Storage Dashboard
- Dashboard with statistics overview
- Blob management interface
- Attachment management interface
- Variant records handling
- Media preview support
- File download functionality
