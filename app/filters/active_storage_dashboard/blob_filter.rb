# frozen_string_literal: true

module ActiveStorageDashboard
  class BlobFilter
    EXACT_MATCH_FILTERS = %i[key service_name content_type].freeze

    SIZE_RANGES = {
      "small" => -> { where("byte_size < ?", 1.megabyte) },
      "medium" => -> { where("byte_size >= ? AND byte_size <= ?", 1.megabyte, 10.megabytes) },
      "large" => -> { where("byte_size > ?", 10.megabytes) }
    }.freeze

    STATUS_FILTERS = {
      "purgable" => -> { left_outer_joins(:attachments).where(active_storage_attachments: { id: nil }) },
      "attached" => -> { joins(:attachments).distinct }
    }.freeze

    def initialize(scope, params)
      @scope = scope
      @params = params
    end

    def apply
      filter_exact_matches
      filter_filename
      filter_size
      filter_status
      @scope
    end

    private

    def filter_exact_matches
      filters = @params.slice(*EXACT_MATCH_FILTERS).compact_blank
      @scope = @scope.where(filters) if filters.any?
    end

    def filter_filename
      return unless @params[:filename].present?

      @scope = @scope.where("filename LIKE ?", "%#{@params[:filename]}%")
    end

    def filter_size
      return unless @params[:size].present?

      filter = SIZE_RANGES[@params[:size]]
      @scope = @scope.instance_exec(&filter) if filter
    end

    def filter_status
      return unless @params[:status].present?

      filter = STATUS_FILTERS[@params[:status]]
      @scope = @scope.instance_exec(&filter) if filter
    end
  end
end
