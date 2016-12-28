Rails.application.routes.draw do

  resources :users, only: [] do
    # Add user organization filters
    resources :user_activity_line_item_filters do
      get 'use'
    end
  end

  # Budget Forcast
  # resources :budgets,   :only => [:index] do
  #   collection do
  #     post  'set'
  #     post  'alter'
  #   end
  # end

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
  # resources :funding_requests, :only => [:index]

  # Capital Project Controllers
  resources :capital_projects do

    collection do
      get   'builder'
      post  'runner'
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
      end
    end

  end

  resources :activity_line_items, :only => [] do
    resources :comments
    resources :documents
  end

end
