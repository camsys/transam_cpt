Rails.application.routes.draw do

  resources :users, only: [] do
    # Add user organization filters
    resources :user_activity_line_item_filters do
      get 'use'
    end
  end

  # Asset replacement/rehabilitation
  resources :planning, :only => [:index] do
    collection do
      get   'load_chart'
      get   'asset_action'
      get   'move_assets'
      post  'ali_action'
      post  'add_funds'
      post  'update_cost'
      post  'edit_asset'
      post  'move_ali'
    end
  end

  resources :team_codes, :only => [] do
    collection do
      get  'children'
    end
  end

  # Capital Project Controllers
  resources :capital_projects do

    collection do
      get   'builder'
      get   'get_dashboard_summary'
      get   'find_districts'
      post  'runner'
      get   'activity_line_items'
      get   'table'
    end

    member do
      get 'load_view'
      get 'copy'
      get 'fire_workflow_event'
      get 'alis'
    end

    resources :comments
    resources :documents

    resources :activity_line_items do

      # resources :funding_plans, :only => [:create, :destroy]
      member do
        get 'assets'
        get 'get_asset_summary'
        get 'edit_cost'
        get 'restore_cost'
        post 'set_cost'
        get 'edit_milestones'
        get 'add_asset'
        delete 'remove_asset'
        get 'pin'
      end
    end

  end

  resources :activity_line_items, :only => [:show] do
    resources :comments
    resources :documents
    resources :tasks
  end

  resources :capital_plans, :only => [:index, :show] do
    collection do
      get 'complete_actions'
      get 'get_checkboxes'
    end
  end

  resources :scenarios, only: [:index, :show] do
    member do 
      put 'transition'
    end
  end

end
