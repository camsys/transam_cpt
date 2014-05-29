Rails.application.routes.draw do
  
  # Capital Project Controllers
  resources :capital_projects do
    
    collection do
      get   'builder'
      post  'runner'
    end
    
    resources :comments
    resources :documents
    
    resources :activity_line_items do
      resources :comments      
    end
    
  end
  
  resources :activity_line_items do
    resources :comments, :documents
  end
  
end
