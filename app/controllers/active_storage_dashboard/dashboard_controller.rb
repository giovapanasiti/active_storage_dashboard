# frozen_string_literal: true

module ActiveStorageDashboard
  class DashboardController < ApplicationController
    def index
      @blobs_count = ActiveStorage::Blob.count
      @attachments_count = ActiveStorage::Attachment.count
      @variant_records_count = defined?(ActiveStorage::VariantRecord) ? ActiveStorage::VariantRecord.count : 0
      
      @total_storage = ActiveStorage::Blob.sum(:byte_size)
      @content_types = ActiveStorage::Blob.group(:content_type).count.sort_by { |_, count| -count }.first(5)
      
      @recent_blobs = ActiveStorage::Blob.order(created_at: :desc).limit(5)
    end
  end
end 