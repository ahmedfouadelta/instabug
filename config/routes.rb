require 'sidekiq/web'

# Configure Sidekiq-specific session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_interslice_session"

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  
  post 'applications/create', to: "applications#create"
  get 'applications/show', to: "applications#show"
  put 'applications/update', to: "applications#update"

  post 'chats/create', to: "chats#create"
  get 'chats', to: "chats#index"
  get 'chats/show', to: "chats#show"

  get 'messages/create'

  get 'messages/update'

  get 'messages/show'

  get 'messages/list'

  get 'messages/search'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "about", to: "abouts#index"
end
