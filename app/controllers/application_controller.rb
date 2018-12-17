class ApplicationController < ActionController::API
  before_action :ensure_json_request

  private
    def vocabulary
      @vocabulary ||= Vocabulary.find_by(string_key: params['vocabulary_string_key'])
    end

    def valid_vocabulary?
      if vocabulary.blank?
        render json: URIService::JSON.errors('Vocabulary not found.'), status: 404
      end
    end

    def ensure_json_request
      return if request.format == :json
      head :not_acceptable
    end
end
