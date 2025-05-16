# frozen_string_literal: true

module ActiveStorageDashboard
  class VariantRecordsController < ApplicationController
    def index
      if defined?(ActiveStorage::VariantRecord)
        @variant_records = paginate(ActiveStorage::VariantRecord.order(id: :desc))
        @total_count = ActiveStorage::VariantRecord.count
      else
        @variant_records = []
        @total_count = 0
      end
    end

    def show
      if defined?(ActiveStorage::VariantRecord)
        @variant_record = ActiveStorage::VariantRecord.find(params[:id])
        @blob = @variant_record.blob
      else
        redirect_to root_path, alert: "Variant Records are not available in this Rails version"
      end
    end
  end
end 