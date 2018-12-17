class ApplicationController < ActionController::API

  private
    def vocabulary
      @vocabulary ||= Vocabulary.find_by(string_key: params['vocabulary_string_key'])
    end

    def valid_vocabulary?
      if vocabulary.blank?
        render json: URIService::JSON.errors('Vocabulary not found.'), status: 404
      end
    end
end
