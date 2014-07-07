Rails.application.routes.draw do
  
  resources :funding_sources do
    member do
      get 'modify_amounts'
      post 'update_amounts'
    end
    
  end

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
      resources :comments      
      member do
        get 'add_asset'
        get 'remove_asset'
      end
    end
    
  end
  
  resources :activity_line_items do
    resources :comments, :documents
  end
  
end
