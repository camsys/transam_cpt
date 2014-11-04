Rails.application.routes.draw do
    
  # Budget Forcast
  resources :budgets,   :only => [:index] do
    collection do
      post  'set'
      post  'alter'
    end
  end

  # Asset replacement/rehabilitation
  resources :planning, :only => [:index] do
    collection do
      get  'load_chart'
      post  'asset_action'
      post  'ali_action'
      post  'add_funds'
      post  'update_cost'
      post  'edit_asset'
      post  'move_ali'
    end
  end
    
  # Asset replacement/rehabilitation
  resources :scheduler, :only => [:index] do
    collection do
      post  'scheduler_action'
      get   'scheduler_swimlane_action'
      post  'scheduler_ali_action'
      get   'scheduler_ali_action'
      get   'loader'
      post  'edit_asset_in_modal'
      post  'update_cost_modal'
      post  'add_funding_plan_modal'
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
