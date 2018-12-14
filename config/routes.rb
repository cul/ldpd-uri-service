Rails.application.routes.draw do
  scope '/api' do
    namespace :v1 do
      resources :vocabularies, param: :string_key do
        resources :terms, param: :uri, constraints: { uri: /.*/ }

        collection do
          match '', via: :options, action: 'options'
        end
      end
    end
  end
end
