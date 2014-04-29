Rails.application.routes.draw do
  
  resources :capital_projects do
    resources :comments
    resources :documents
  end
  
end
