# frozen_string_literal: true

module ActiveStorageDashboard
  class AttachmentsController < ApplicationController
    def index
      @attachments = ActiveStorage::Attachment.order(created_at: :desc)
      
      # Get record types for filter dropdown
      @record_types = ActiveStorage::Attachment.distinct.pluck(:record_type).compact.sort
      
      # Get content types for filter dropdown
      @content_types = ActiveStorage::Blob.joins(:attachments).distinct.pluck(:content_type).compact.sort
      
      # Apply filters
      apply_filters
      
      # Pagination after filters
      @total_count = @attachments.count
      @attachments = paginate(@attachments)
    end

    def show
      @attachment = ActiveStorage::Attachment.find(params[:id])
      @blob = @attachment.blob
    end
    
    def download
      @attachment = ActiveStorage::Attachment.find(params[:id])
      @blob = @attachment.blob
      
      # Pass along the disposition parameter if present
      if params[:disposition].present?
        redirect_to download_blob_path(@blob, disposition: params[:disposition])
      else
        redirect_to download_blob_path(@blob)
      end
    end

    private
    
    def apply_filters
      # Filter by attachment name
      if params[:name].present?
        @attachments = @attachments.where('name LIKE ?', "%#{params[:name]}%")
      end
      
      # Filter by record type
      if params[:record_type].present?
        @attachments = @attachments.where(record_type: params[:record_type])
      end
      
      # Filter by content type
      if params[:content_type].present?
        @attachments = @attachments.joins(:blob).where(active_storage_blobs: { content_type: params[:content_type] })
      end
    end
  end
end 