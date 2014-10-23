Rails.application.routes.draw do
  
  resources :organizations, :controller => 'cpt_organizations' do
  end
  
  resources :funding_sources do
    collection do
        get 'details'      
    end
  end
  
  resources :funding_line_items do
    resources :comments
    resources :documents
  end
  
  # Asset replacement/rehabilitation
  resources :scheduler, :only => [:index] do
    collection do
      post  'scheduler_action'
      post  'scheduler_ali_action'
      get   'loader'
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
      get 'copy'
      get 'fire_workflow_event'
    end
        
    resources :comments
    resources :documents
    
    resources :activity_line_items do
      
      resources :funding_requests
      resources :comments      
      
      member do
        get 'edit_cost'
        post 'set_cost'
        get 'edit_milestones'
        get 'add_asset'
        delete 'remove_asset'
      end
    end
    
  end
    
end
