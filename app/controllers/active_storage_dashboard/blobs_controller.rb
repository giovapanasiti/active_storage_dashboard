# frozen_string_literal: true

module ActiveStorageDashboard
  class BlobsController < ApplicationController
    def index
      @blobs = paginate(ActiveStorage::Blob.order(created_at: :desc))
      @total_count = ActiveStorage::Blob.count
    end

    def show
      @blob = ActiveStorage::Blob.find(params[:id])
      @attachments = @blob.attachments
      @variant_records = defined?(ActiveStorage::VariantRecord) ? @blob.variant_records : []
    end
    
    def download
      @blob = ActiveStorage::Blob.find(params[:id])
      
      # Different approaches depending on Rails version
      if @blob.respond_to?(:open)
        # Rails 6.0+: Use the open method to get the file
        begin
          @blob.open do |file|
            send_data file.read, 
                      filename: @blob.filename.to_s, 
                      type: @blob.content_type || 'application/octet-stream', 
                      disposition: 'attachment'
          end
        rescue => e
          Rails.logger.error("Failed to download blob: #{e.message}")
          redirect_to blob_path(@blob), alert: "Download failed: #{e.message}"
        end
      elsif @blob.respond_to?(:download)
        # Alternative approach: Use the download method
        begin
          send_data @blob.download, 
                    filename: @blob.filename.to_s, 
                    type: @blob.content_type || 'application/octet-stream', 
                    disposition: 'attachment'
        rescue => e
          Rails.logger.error("Failed to download blob: #{e.message}")
          redirect_to blob_path(@blob), alert: "Download failed: #{e.message}"
        end
      else
        # Fallback: Redirect to main app blob path
        redirect_to main_app.rails_blob_path(@blob, disposition: 'attachment')
      end
    end
  end
end 