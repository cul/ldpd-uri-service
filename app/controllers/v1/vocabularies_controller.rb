module V1
  class VocabulariesController < ApplicationController
    SHOW_FIELDS = [:string_key, :label, :custom_fields].freeze

    # GET /vocabularies
    def index
      vocabularies = Vocabulary.all
      render json: { vocabularies: vocabularies.map { |v| v.as_json(only: SHOW_FIELDS) } }.to_json
    end

    # GET /vocabularies/:string_key
    def show
      if (vocabulary = Vocabulary.find_by(string_key: params[:string_key]))
        render json: vocabulary.to_json(only: SHOW_FIELDS), status: 200
      else
        render json: { errors: [{ title: 'Not Found' }] }.to_json, status: 404
      end
    end

    # POST /vocabularies
    def create
      vocabulary = Vocabulary.new(create_params)
      if vocabulary.save
        render json: vocabulary.to_json(only: SHOW_FIELDS), status: 201
      else
        render json: { errors: vocabulary.errors.full_messages.map { |e| { title: e } } }, status: 400 # each error should be its own error
      end
    end

    # PATCH /vocabularies/:string_key
    def update
      vocabulary = Vocabulary.find_by(string_key: params[:string_key])

      if vocabulary.nil?
        render json: { errors: [{ title: 'Not Found' }] }, status: 404
      elsif vocabulary.update(update_params)
        render json: vocabulary.to_json(only: SHOW_FIELDS), status: 200
      else
        render json: { errors: vocabulary.errors.full_messages.map { |e| { title: e } } }, status: 400
      end
    end

    # DELETE /vocabularies/:string_key
    def destroy
      vocabulary = Vocabulary.find_by(string_key: params[:string_key])

      if vocabulary.nil?
        render json: { errors: [{ title: 'Not Found' }] }, status: 404
      elsif vocabulary.destroy
        head :no_content
      else
        render json: { errors: [{ title: 'Deleting was unsuccessful.' }] }, status: 500
      end
    end

    def options; end

    private

      def create_params
        params.permit(:string_key, :label)
      end

      def update_params
        params.permit(:label)
      end
  end
end
