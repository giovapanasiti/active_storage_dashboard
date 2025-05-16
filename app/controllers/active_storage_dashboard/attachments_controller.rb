# frozen_string_literal: true

module ActiveStorageDashboard
  class AttachmentsController < ApplicationController
    def index
      @attachments = paginate(ActiveStorage::Attachment.order(created_at: :desc))
      @total_count = ActiveStorage::Attachment.count
    end

    def show
      @attachment = ActiveStorage::Attachment.find(params[:id])
      @blob = @attachment.blob
    end
    
    def download
      @attachment = ActiveStorage::Attachment.find(params[:id])
      @blob = @attachment.blob
      
      # Redirect to the blob download action
      redirect_to download_blob_path(@blob)
    end
  end
end 