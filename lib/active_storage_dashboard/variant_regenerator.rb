module ActiveStorageDashboard
  class VariantRegenerator
    def self.call
      unless defined?(ActiveStorage::VariantRecord)
        puts "ActiveStorage::VariantRecord not found (Rails < 7.1). Skipping."
        return
      end

      ActiveStorage::VariantRecord.find_each do |variant|
        begin
          variant.image.representation(variant.variation).processed
        rescue => e
          warn "Failed variant #{variant.id}: #{e.message}"
        end
      end
    end
  end
end