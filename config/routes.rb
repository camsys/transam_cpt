Rails.application.routes.draw do
  
  resources :capital_projects do
    resources :comments
    resources :documents
    resources :activity_line_items
  end
  
end
