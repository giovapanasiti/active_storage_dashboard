# frozen_string_literal: true

module ActiveStorageDashboard
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    
    # Simple pagination without external dependencies
    helper_method :paginate

    def paginate(scope, per_page = 20)
      @page = [params[:page].to_i, 1].max
      scope.limit(per_page).offset((@page - 1) * per_page)
    end
  end
end 