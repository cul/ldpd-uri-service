module V1
  class VocabulariesController < ApplicationController
    # GET /vocabularies
    def index
      vocabs = Vocabulary.order(:label).offset(offset).limit(limit)
      render json: URIService::JSON.vocabularies(vocabs)
                                   .merge(limit: limit, offset: offset, total_records: Vocabulary.all.size)
    end

    # GET /vocabularies/:string_key
    def show
      if (vocabulary = Vocabulary.find_by(string_key: params[:string_key]))
        render json: URIService::JSON.vocabulary(vocabulary), status: 200
      else
        render json: URIService::JSON.errors('Not Found'), status: 404
      end
    end

    # POST /vocabularies
    def create
      vocabulary = Vocabulary.new(create_params)

      if vocabulary.save
        render json: URIService::JSON.vocabulary(vocabulary), status: 201
      else
        render json: URIService::JSON.errors(vocabulary.errors.full_messages),
               status: (vocabulary.errors.added?(:string_key, :taken)) ? 409 : 400
      end
    end

    # PATCH /vocabularies/:string_key
    def update
      vocabulary = Vocabulary.find_by(string_key: params[:string_key])

      if vocabulary.nil?
        render json: URIService::JSON.errors('Not Found'), status: 404
      elsif vocabulary.update(update_params)
        render json: URIService::JSON.vocabulary(vocabulary), status: 200
      else
        render json: URIService::JSON.errors(vocabulary.errors.full_messages), status: 400
      end
    end

    # DELETE /vocabularies/:string_key
    def destroy
      vocabulary = Vocabulary.find_by(string_key: params[:string_key])

      if vocabulary.nil?
        render json: URIService::JSON.errors('Not Found'), status: 404
      elsif vocabulary.destroy
        head :no_content
      else
        render json: URIService::JSON.errors('Deleting was unsuccessful.'), status: 500
      end
    end

    private

      def create_params
        params.require(:vocabulary).permit(:string_key, :label, :locked)
      end

      def update_params
        params.require(:vocabulary).permit(:label, :locked)
      end
  end
end
