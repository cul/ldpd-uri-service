module V1
  class CustomFieldsController < ApplicationController
    before_action :valid_vocabulary?, :unlocked_vocabulary?, :field_key_present?

    def create
      if vocabulary.custom_fields.key?(create_params[:field_key])
        render json: URIService::JSON.errors('Field key already exists'), status: 409
      else
        vocabulary.add_custom_field(create_params)

        if vocabulary.save
          render json: URIService::JSON.custom_field(vocabulary, create_params[:field_key]), status: 201
        else
          render json: URIService::JSON.errors(vocabulary.errors.full_messages), status: 400
        end
      end
    end

    def update
      if vocabulary.custom_fields.key?(params[:field_key])
        vocabulary.update_custom_field(update_params)

        if vocabulary.save
          render json: URIService::JSON.custom_field(vocabulary, params[:field_key]), status: 200
        else
          render json: URIService::JSON.errors(vocabulary.errors.full_messages), status: 400
        end
      else
        render json: URIService::JSON.errors('Not Found'), status: 404
      end
    end

    def destroy
      if vocabulary.custom_fields.key?(params[:field_key])
        vocabulary.delete_custom_field(params[:field_key])

        if vocabulary.save
          head :no_content
        elsif
          render json: URIService::JSON.errors(vocabulary.errors.full_messages), status: 400
        end
      else
        render json: URIService::JSON.errors('Not Found'), status: 404
      end
    end

    private

      def field_key_present?
        if (action_name == 'create' ? params.dig(:custom_field, :field_key) : params.fetch(:field_key, nil)).blank?
          render json: URIService::JSON.errors('Field key must be present.'), status: 400
        end
      end

      def create_params
        params.require(:custom_field).permit(:field_key, :label, :data_type)
      end

      def update_params
        params.require(:custom_field).permit(:label).to_h.merge(field_key: params[:field_key])
      end
  end
end
