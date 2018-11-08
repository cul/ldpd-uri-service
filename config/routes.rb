Rails.application.routes.draw do
  scope '/api' do
    namespace :v1 do
      resources :vocabularies, param: :string_key do
        collection do
          match '', via: :options, action: 'options'
        end
      end
    end
  end
end
