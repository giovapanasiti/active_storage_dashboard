# frozen_string_literal: true

ActiveStorageDashboard::Engine.routes.draw do
  root to: 'dashboard#index'
  
  resources :blobs, only: [:index, :show], path: 'blobs' do
    member do
      get :download
    end
  end
  
  resources :attachments, only: [:index, :show], path: 'attachments' do
    member do
      get :download
    end
  end
  
  resources :variant_records, only: [:index, :show], path: 'variant_records'
end 