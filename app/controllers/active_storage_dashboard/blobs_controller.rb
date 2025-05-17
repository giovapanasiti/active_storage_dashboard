# frozen_string_literal: true

module ActiveStorageDashboard
  class BlobsController < ApplicationController
    def index
      @blobs = ActiveStorage::Blob.order(created_at: :desc)
      
      # Get content types for filter dropdown
      @content_types = ActiveStorage::Blob.distinct.pluck(:content_type).compact.sort
      
      # Apply filters
      apply_filters

      # Pagination after filters
      @total_count = @blobs.count
      @blobs = paginate(@blobs)
    end

    def show
      @blob = ActiveStorage::Blob.find(params[:id])
      @attachments = @blob.attachments
      @variant_records = defined?(ActiveStorage::VariantRecord) ? @blob.variant_records : []
    end
    
    def download
      @blob = ActiveStorage::Blob.find(params[:id])
      
      # Determine the disposition (inline for preview, attachment for download)
      # Params can be route params or query params
      disposition = params[:disposition] || 'attachment'
      
      # Different approaches depending on Rails version
      if @blob.respond_to?(:open)
        # Rails 6.0+: Use the open method to get the file
        begin
          @blob.open do |file|
            send_data file.read, 
                      filename: @blob.filename.to_s, 
                      type: @blob.content_type || 'application/octet-stream', 
                      disposition: disposition
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
                    disposition: disposition
        rescue => e
          Rails.logger.error("Failed to download blob: #{e.message}")
          redirect_to blob_path(@blob), alert: "Download failed: #{e.message}"
        end
      else
        # Fallback: Redirect to main app blob path
        disposition_param = disposition == 'inline' ? { disposition: 'inline' } : { disposition: 'attachment' }
        redirect_to main_app.rails_blob_path(@blob, disposition_param)
      end
    end

    private
    
    def apply_filters
      # Filter by content type
      if params[:content_type].present?
        @blobs = @blobs.where(content_type: params[:content_type])
      end
      
      # Filter by size
      if params[:size].present?
        case params[:size]
        when 'small'
          @blobs = @blobs.where('byte_size < ?', 1.megabyte)
        when 'medium'
          @blobs = @blobs.where('byte_size >= ? AND byte_size <= ?', 1.megabyte, 10.megabytes)
        when 'large'
          @blobs = @blobs.where('byte_size > ?', 10.megabytes)
        end
      end
      
      # Filter by status
      if params[:status].present?
        case params[:status]
        when 'purgable'
          @blobs = @blobs.left_outer_joins(:attachments).where(active_storage_attachments: { id: nil })
        when 'attached'
          @blobs = @blobs.joins(:attachments).distinct
        end
      end
    end
  end
end 