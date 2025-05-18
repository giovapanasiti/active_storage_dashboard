namespace :active_storage do
  namespace :dashboard do
    desc "Purge blobs that have no attachments"
    task purge_orphans: :environment do
      ActiveStorageDashboard::OrphanPurger.call
    end

    desc "Re-analyze blobs that are not yet analyzed"
    task reanalyze: :environment do
      ActiveStorageDashboard::Analyzer.call
    end

    desc "Recreate missing or outdated variants"
    task regenerate_variants: :environment do
      ActiveStorageDashboard::VariantRegenerator.call
    end

    desc "Run all maintenance tasks"
    task all: [:purge_orphans, :reanalyze, :regenerate_variants]
  end
end