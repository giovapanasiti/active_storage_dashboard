# frozen_string_literal: true

module ActiveStorageDashboard
  module ApplicationHelper
    # Include Rails URL helpers to easily generate blob URLs
    include Rails.application.routes.url_helpers
    
    # Helper to get the main app's routes
    def main_app
      Rails.application.class.routes.url_helpers
    end
    
    # Helper to generate a URL for direct blob viewing (for embedding media)
    def rails_blob_url(blob, disposition: nil)
      # For media embedding, we need a reliable URL to the blob
      if defined?(request) && request.present?
        # Get the proper host from the request
        host = request.base_url
        
        # Different approaches depending on Rails version
        if Rails.gem_version >= Gem::Version.new('6.1') && Rails.application.routes.url_helpers.respond_to?(:rails_storage_proxy_path)
          # Rails 6.1+ uses proxy approach
          return host + Rails.application.routes.url_helpers.rails_storage_proxy_path(blob, disposition: disposition)
        elsif Rails.application.routes.url_helpers.respond_to?(:rails_service_blob_path)
          # Rails 5.2-6.0
          return host + Rails.application.routes.url_helpers.rails_service_blob_path(blob.key, disposition: disposition)
        elsif Rails.application.routes.url_helpers.respond_to?(:rails_blob_path)
          # Another approach
          return host + Rails.application.routes.url_helpers.rails_blob_path(blob, disposition: disposition)
        end
      end
      
      # Fallback to direct service URL
      if blob.respond_to?(:url)
        return blob.url(disposition: disposition)
      elsif blob.respond_to?(:service_url)
        return blob.service_url(disposition: disposition)
      end
      
      # Last resort - return path to download action in our engine
      active_storage_dashboard.download_blob_path(blob)
    end
    
    def pagination_links(total_count, per_page = 20)
      return if total_count <= per_page
      
      total_pages = (total_count.to_f / per_page).ceil
      current_page = [@page.to_i, 1].max
      
      content_tag :div, class: 'pagination' do
        html = []
        
        if current_page > 1
          html << link_to('« Previous', url_for(page: current_page - 1), class: 'pagination-link')
        else
          html << content_tag(:span, '« Previous', class: 'pagination-link disabled')
        end
        
        # Show window of pages
        window_size = 5
        window_start = [1, current_page - (window_size / 2)].max
        window_end = [total_pages, window_start + window_size - 1].min
        
        # Adjust window_start if we're at the end
        window_start = [1, window_end - window_size + 1].max
        
        # First page
        if window_start > 1
          html << link_to('1', url_for(page: 1), class: 'pagination-link')
          html << content_tag(:span, '...', class: 'pagination-ellipsis') if window_start > 2
        end
        
        # Page window
        (window_start..window_end).each do |page|
          if page == current_page
            html << content_tag(:span, page, class: 'pagination-link current')
          else
            html << link_to(page, url_for(page: page), class: 'pagination-link')
          end
        end
        
        # Last page
        if window_end < total_pages
          html << content_tag(:span, '...', class: 'pagination-ellipsis') if window_end < total_pages - 1
          html << link_to(total_pages, url_for(page: total_pages), class: 'pagination-link')
        end
        
        if current_page < total_pages
          html << link_to('Next »', url_for(page: current_page + 1), class: 'pagination-link')
        else
          html << content_tag(:span, 'Next »', class: 'pagination-link disabled')
        end
        
        safe_join(html)
      end
    end
    
    def format_bytes(bytes)
      return '0 B' if bytes.nil? || bytes == 0
      
      units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB']
      exponent = (Math.log(bytes) / Math.log(1024)).to_i
      exponent = [exponent, units.size - 1].min
      
      converted = bytes.to_f / (1024 ** exponent)
      "#{format('%.2f', converted)} #{units[exponent]}"
    end
    
    # Check if a blob can be previewed
    def previewable_blob?(blob)
      return false unless blob.present?
      
      # Check for representable content based on content type
      content_type = blob.content_type
      return false unless content_type.present?
      
      image_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
      return true if image_types.include?(content_type)
      
      # Check for previewable content in Rails 6+ using Active Storage's previewable method
      if defined?(ActiveStorage::Blob.new.preview) && 
         blob.respond_to?(:previewable?) && 
         blob.previewable?
        return true
      end
      
      false
    end
    
    # Generate preview HTML for a blob
    def blob_preview(blob)
      return "" unless blob.present?
      
      content_type = blob.content_type
      
      if content_type&.start_with?('image/')
        url = Rails.application.routes.url_helpers.rails_blob_url(blob, disposition: "inline", only_path: true)
        return image_tag(url, alt: blob.filename)
      elsif defined?(ActiveStorage::Blob.new.preview) && 
            blob.respond_to?(:previewable?) && 
            blob.previewable?
        # This will work in Rails 6+ with proper preview handlers configured
        begin
          url = Rails.application.routes.url_helpers.rails_blob_url(
            blob.preview(resize: "300x300").processed.image, 
            disposition: "inline", 
            only_path: true
          )
          return image_tag(url, alt: blob.filename, class: "preview-image")
        rescue => e
          # Fallback if preview fails for any reason
          Rails.logger.error("Preview generation failed: #{e.message}")
          return content_tag(:div, "Preview not available", class: "preview-error")
        end
      end
      
      return content_tag(:div, "No preview available", class: "no-preview")
    end
    
    # Check if an attachment can be previewed
    def previewable_attachment?(attachment)
      return false unless attachment&.blob&.present?
      
      previewable_blob?(attachment.blob)
    end
    
    # Generate preview HTML for an attachment
    def attachment_preview(attachment)
      return "" unless attachment&.blob&.present?
      
      blob_preview(attachment.blob)
    end
    
    # Helper to generate a download URL for a blob
    def download_blob_url(blob)
      begin
        # Try simple direct download URL first using the blob's service URL
        # This is often the most reliable method
        if blob.respond_to?(:service_url)
          return blob.service_url(disposition: "attachment", filename: blob.filename.to_s)
        end
        
        # If we're in a Rails 6.1+ app, use the direct representation URL
        if Rails.gem_version >= Gem::Version.new('6.1') &&
           blob.respond_to?(:representation) &&
           Rails.application.routes.url_helpers.respond_to?(:rails_blob_representation_url)
          
          # Force a download by using the blob directly
          return Rails.application.routes.url_helpers.rails_blob_url(blob, disposition: "attachment")
        end
        
        # For Rails 6.0, use standard blob URL approach
        if Rails.application.routes.url_helpers.respond_to?(:rails_blob_url)
          host_options = {}
          
          # Make sure we have a host set for URL generation
          if defined?(request) && request.present?
            host_options[:host] = request.host
            host_options[:port] = request.port if request.port != 80 && request.port != 443
            host_options[:protocol] = request.protocol.sub('://', '')
          elsif Rails.application.config.action_controller.default_url_options[:host].present?
            host_options = Rails.application.config.action_controller.default_url_options
          else
            # Fallback to localhost for development
            host_options[:host] = 'localhost'
            host_options[:port] = 3000
            host_options[:protocol] = 'http'
          end
          
          # Ensure disposition is set for attachment download
          return Rails.application.routes.url_helpers.rails_blob_url(blob, **host_options, disposition: "attachment")
        end
        
        # For Rails 5.2
        if Rails.application.routes.url_helpers.respond_to?(:rails_service_blob_url)
          host_options = {}
          if defined?(request) && request.present?
            host_options[:host] = request.host
            host_options[:port] = request.port if request.port != 80 && request.port != 443
            host_options[:protocol] = request.protocol.sub('://', '')
          end
          return Rails.application.routes.url_helpers.rails_service_blob_url(blob.key, **host_options, disposition: "attachment")
        end
        
        # If all else fails, use the direct download path (for development)
        if Rails.application.routes.url_helpers.respond_to?(:rails_blob_path)
          return Rails.application.routes.url_helpers.rails_blob_path(blob, disposition: "attachment")
        end
        
        Rails.logger.error("Could not determine download URL for blob #{blob.id}")
        return "#"
      rescue => e
        Rails.logger.error("Error generating download URL: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        return "#"
      end
    end

    # Ensure we're properly using the engine routes
    def active_storage_dashboard
      ActiveStorageDashboard::Engine.routes.url_helpers
    end

    # Fix URL generation by explicitly using the engine routes
    def download_attachment_path(attachment)
      active_storage_dashboard.download_attachment_path(attachment)
    end

    def download_blob_path(blob)
      active_storage_dashboard.download_blob_path(blob)
    end

    def attachment_path(attachment)
      active_storage_dashboard.attachment_path(attachment)
    end

    def blob_path(blob)
      active_storage_dashboard.blob_path(blob)
    end

    def attachments_path
      active_storage_dashboard.attachments_path
    end

    def blobs_path
      active_storage_dashboard.blobs_path
    end

    def variant_records_path
      active_storage_dashboard.variant_records_path
    end

    def variant_record_path(variant_record)
      active_storage_dashboard.variant_record_path(variant_record)
    end
  end
end 