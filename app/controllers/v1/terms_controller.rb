module V1
  class TermsController < ApplicationController
    before_action :valid_vocabulary?

    # GET /vocabularies/:string_key/terms
    def index
      if valid_search_params?
        solr_response = URIService.solr.search do |solr_params|
          solr_params.vocabulary params[:vocabulary_string_key]
          solr_params.q          params[:q]
          solr_params.authority  params[:authority]
          solr_params.uri        params[:uri]
          solr_params.pref_label params[:pref_label]
          solr_params.alt_label  params[:alt_label]
          solr_params.term_type  params[:term_type]
          solr_params.pagination per_page, page

          custom_fields.each do |k, v|
            if params[k]
              solr_params.fq("#{k}#{URIService.solr_suffix(v[:data_type])}", params[k])
            end
          end
        end

        response = URIService::JSON.term_search(solr_response)
      else
        response = { page: page, per_page: per_page, total_records: 0, terms: [] }
      end

      render json: response, status: 200
    end

    # GET /vocabularies/:string_key/terms/:uri
    def show
      if (term = URIService.solr.find_term(params[:vocabulary_string_key], params[:uri]))
        render json: URIService::JSON.term(term), status: 200
      else
        render json: URIService::JSON.errors('Not Found'), status: 404
      end
    end

    # POST /vocabularies/:string_key/terms
    def create
      term = Term.new(create_params)
      term.vocabulary = vocabulary

      custom_fields.each do |f, v|
        next unless params[:term].key?(f)
        term.set_custom_field(f, params[:term][f])
      end

      if term.save
        render json: URIService::JSON.term(term), status: 201
      else
        render json: URIService::JSON.errors(term.errors.full_messages),
               status: term.errors.added?(:uri_hash, :taken) ? 409 : 400
      end
    end

    # PATCH /vocabularies/:string_key/terms/:uri
    def update
      term = Term.find_by(vocabulary: vocabulary, uri: params[:uri])

      if term.nil?
        render json: URIService::JSON.errors('Not Found'), status: 404
      else
        term.assign_attributes(update_params) # updates, but doesn't save.

        custom_fields.each do |f, v|
          next unless params[:term].key?(f)
          term.set_custom_field(f, params[:term][f])
        end

        if term.save
          render json: URIService::JSON.term(term), status: 200
        else
          render json: URIService::JSON.errors(term.errors.full_messages), status: 400
        end
      end
    end

    # DELETE /vocabularies/:string_key/terms/:uri
    def destroy
      term = Term.find_by(vocabulary: vocabulary, uri: params[:uri])

      if term.nil?
        render json: URIService::JSON.errors('Not Found'), status: 404
      elsif term.destroy
        head :no_content
      else
        render json: URIService::JSON.errors('Deleting was unsuccessful.'), status: 500
      end
    end

    # OPTIONS /vocabularies/:string_key/terms
    def options
    end

    private

      def page
        page = (params[:page].blank?) ? 1 : params[:page].to_i
        page = 1 if page < 1
        page
      end

      def per_page
        per_page = (params[:per_page].blank?) ? URIService::DEFAULT_PER_PAGE : params[:per_page].to_i
        per_page = URIService::DEFAULT_PER_PAGE if per_page < 1
        per_page = URIService::MAX_PER_PAGE     if per_page > URIService::MAX_PER_PAGE
        per_page
      end

      def valid_search_params?
        # TODO: 'term' key is added by rails even though the value is not set in
        # the request. Something to look into in the future.
        valid_params = [
          'action', 'controller', 'format', 'vocabulary_string_key', 'q', 'uri',
          'authority', 'pref_label', 'alt_label', 'term_type', 'per_page', 'page', 'term'
        ].concat(custom_fields.keys)
        Rails.logger.debug params.keys
        params.keys.all? { |i| valid_params.include?(i) }
      end

      def custom_fields
        vocabulary.custom_fields
      end

      def create_params
        params.require(:term).permit(:pref_label, :uri, :authority, :term_type, :uuid, alt_label: [])
      end

      def update_params
        params.require(:term).permit(:pref_label, :authority, alt_label: [])
      end
  end
end
