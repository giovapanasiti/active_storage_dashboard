module ActiveStorageDashboard
  class Analyzer
    def self.call
      ActiveStorage::Blob.find_each do |blob|
        blob.analyze unless blob.analyzed?
      end
    end
  end
end