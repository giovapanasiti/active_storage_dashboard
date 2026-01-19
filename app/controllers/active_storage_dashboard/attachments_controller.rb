# frozen_string_literal: true

module ActiveStorageDashboard
  class AttachmentsController < ApplicationController
    def index
      @attachments = ActiveStorage::Attachment.order(created_at: :desc)

      # Get filter dropdown options
      @record_types = ActiveStorage::Attachment.distinct.pluck(:record_type).compact.sort
      @content_types = ActiveStorage::Blob.joins(:attachments).distinct.pluck(:content_type).compact.sort

      # Apply filters
      @attachments = AttachmentFilter.new(@attachments, params).apply

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
  end
end 