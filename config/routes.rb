Rails.application.routes.draw do
  
  resources :organizations, :controller => 'cpt_organizations' do
    member do
      get 'edit_budget'
      post 'update_budget'
     end
  end
  
  resources :funding_sources do
    member do
      get 'edit_amounts'
      post 'update_amounts'
    end
  end
  
  # Asset replacement/rehabilitation
  resources :scheduler, :only => [:index] do
    member do
      get 'action'
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
        get 'edit_milestones'
        get 'add_asset'
        delete 'remove_asset'
      end
    end
    
  end
    
end
