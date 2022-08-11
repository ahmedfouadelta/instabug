Rails.application.routes.draw do
  get 'messages/create'

  get 'messages/update'

  get 'messages/show'

  get 'messages/list'

  get 'messages/search'

  get 'chats/create'

  get 'chats/index'

  get 'chats/show'

  get 'apps/create'

  get 'apps/show'

  get 'apps/update'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "about", to: "about#index"
end
