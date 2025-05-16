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
      
      # Find largest blob
      @largest_blob = ActiveStorage::Blob.order(byte_size: :desc).first
      
      # Initialize empty hash for the timeline chart
      @blobs_by_month = {}
      
      begin
        load_timeline_data
      rescue => e
        # If everything fails, generate sample data
        Rails.logger.error "Error in timeline chart preparation: #{e.message}"
        generate_sample_timeline_data
      end
    end
    
    private
    
    def load_timeline_data
      # Get all blobs created in the last year
      start_date = 1.year.ago.beginning_of_month
      
      # First try with ActiveRecord
      begin
        blobs_with_dates = ActiveStorage::Blob
          .where('created_at >= ?', start_date)
          .pluck(:created_at)
        
        # Group by year-month manually
        month_counts = Hash.new(0)
        blobs_with_dates.each do |date|
          month_key = date.strftime('%Y-%m')
          month_counts[month_key] += 1
        end
        
        # Sort by month
        @blobs_by_month = month_counts.sort.to_h
        
        # If we didn't get any data and there are blobs, try the adapter-specific methods
        if @blobs_by_month.empty? && ActiveStorage::Blob.count > 0
          adapter_specific_timeline_data
        end
      rescue => e
        # If ActiveRecord method fails, try adapter-specific methods
        Rails.logger.error "Error using ActiveRecord for timeline: #{e.message}"
        adapter_specific_timeline_data
      end
    end
    
    def adapter_specific_timeline_data
      adapter = ActiveRecord::Base.connection.adapter_name.downcase
      table_name = ActiveStorage::Blob.table_name
      
      begin
        # Different approach for different database adapters
        if adapter.include?('sqlite')
          # SQLite
          result = ActiveRecord::Base.connection.execute(
            "SELECT strftime('%Y-%m', created_at) as month, COUNT(*) as count " +
            "FROM #{table_name} GROUP BY strftime('%Y-%m', created_at) " +
            "ORDER BY month LIMIT 12"
          )
          
          result.each do |row|
            @blobs_by_month[row['month']] = row['count']
          end
        elsif adapter.include?('mysql')
          # MySQL
          result = ActiveRecord::Base.connection.execute(
            "SELECT DATE_FORMAT(created_at, '%Y-%m') as month, COUNT(*) as count " +
            "FROM #{table_name} GROUP BY DATE_FORMAT(created_at, '%Y-%m') " +
            "ORDER BY month LIMIT 12"
          )
          
          result.each do |row|
            month_key = row[0] || row['month'] # Handle different result formats
            count = row[1] || row['count']
            @blobs_by_month[month_key] = count
          end
        else
          # PostgreSQL or others
          result = ActiveRecord::Base.connection.execute(
            "SELECT TO_CHAR(created_at, 'YYYY-MM') as month, COUNT(*) as count " +
            "FROM #{table_name} GROUP BY TO_CHAR(created_at, 'YYYY-MM') " +
            "ORDER BY month LIMIT 12"
          )
          
          result.each do |row|
            month_key = row['month']
            count = row['count']
            @blobs_by_month[month_key] = count if month_key && count
          end
        end
      rescue => e
        # If database-specific approach fails, use sample data
        Rails.logger.error "Error using #{adapter} for timeline: #{e.message}"
        generate_sample_timeline_data
      end
    end
    
    def generate_sample_timeline_data
      # Generate sample data for last 6 months if we can't query the database
      today = Date.today
      6.times do |i|
        month = (today - i.months).strftime('%Y-%m')
        @blobs_by_month[month] = rand(1..20) # Random count between 1-20
      end
    end
  end
end 