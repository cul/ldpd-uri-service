Rails.application.routes.draw do
  scope '/api' do
    namespace :v1, defaults: { format: :json } do
      resources :vocabularies, param: :string_key do
        resources :terms, param: :uri, constraints: { uri: /.*/ }

        collection do
          match '', via: :options, action: 'options'
        end

        resources :custom_fields, param: :field_key, only: [:create, :update, :destroy]
      end
    end
  end
end
