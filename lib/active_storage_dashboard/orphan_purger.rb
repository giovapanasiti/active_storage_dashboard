module ActiveStorageDashboard
  class OrphanPurger
    def self.call
      scope = ActiveStorage::Blob.left_outer_joins(:attachments)
                                 .where(active_storage_attachments: { id: nil })

      scope.find_each do |blob|
        blob.purge
        puts "Purged blob #{blob.id}"
      end
    end
  end
end