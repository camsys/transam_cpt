Rails.application.routes.draw do
  
  resources :funding_sources do
    member do
      get 'edit_amounts'
      post 'update_amounts'
    end
  end
  
  # Funding Requests -- index only
  resources :funding_requests, :only => [:index]

  # Capital Project Controllers
  resources :capital_projects do
    
    # Build controller for CP wizard
    resources :build, controller: 'capital_projects/build'    
    
    collection do
      get   'builder'
      post  'runner'
    end
    
    member do
      get 'shift_fiscal_year'
      get 'copy'
    end
        
    resources :comments
    resources :documents
    
    resources :activity_line_items do
      
      resources :funding_requests
      resources :comments      
      
      member do
        get 'edit_cost'
        get 'add_asset'
        get 'remove_asset'
      end
    end
    
  end
    
end
