class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_token, :ensure_json_request

  rescue_from StandardError do |e|
    Rails.logger.error "#{e}\n\t#{e.backtrace.join("\n\t")}"
    render json: URIService::JSON.errors('Unexpected Error'), status: 500
  end

  private
    def limit
      limit = (params[:limit].blank?) ? URIService::DEFAULT_LIMIT : params[:limit].to_i
      limit = URIService::DEFAULT_LIMIT if limit < 1
      limit = URIService::MAX_LIMIT     if limit > URIService::MAX_LIMIT
      limit
    end

    def offset
      offset = (params[:offset].blank?) ? 0 : params[:offset].to_i
      offset = 0 if offset < 0
      offset
    end

    def vocabulary
      @vocabulary ||= Vocabulary.find_by(string_key: params['vocabulary_string_key'])
    end

    def valid_vocabulary?
      if vocabulary.blank?
        render json: URIService::JSON.errors('Vocabulary not found.'), status: 404
      end
    end

    def unlocked_vocabulary?
      if vocabulary.locked?
        render json: URIService::JSON.errors('Vocabulary is locked.'), status: 400
      end
    end

    def ensure_json_request
      return if request.format == :json
      head :not_acceptable
    end

    def authenticate_token
      unless authentication_status == :ok
        render json: URIService::JSON.errors(authentication_status.to_s.titlecase),
               status: authentication_status
      end
    end

    def authentication_status
      status = :unauthorized
      authenticate_with_http_token do |token, options|
        URIService.api_keys.tap do |valid_api_key|
          status = (valid_api_key.include?(token)) ? :ok : :forbidden
        end
      end
      status
    end
end
