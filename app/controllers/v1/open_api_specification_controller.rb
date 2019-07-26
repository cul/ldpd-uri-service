module V1
  class OpenApiSpecificationController < ApplicationController
    include Swagger::Blocks

    swagger_root do
      key :swagger, '2.0'

      info version: '1.0.0' do
        key :title, 'URI Service API'
        key :description, 'API to manage vocabularies and their associated terms.'
      end

      key :basePath, '/api/v1'
      key :consumes, ['application/json']
      key :produces, ['application/json']

      security_definition :api_key, type: :apiKey do
        key :name, :api_key
        key :in, :header
      end
    end

    swagger_path '/vocabularies' do
      operation :get do
        key :description, 'Returns paginated vocabularies'

        parameter name: :per_page, in: :query, type: :number,
                  minimum: 1, maximum: URIService::MAX_PER_PAGE,
                  description: 'Number of results per page'

        parameter name: :page, in: :query, type: :number,
                  minimum: 1,
                  description: 'Page of paginated results'
      end

      operation :post do
        key :description, 'Creates new vocabulary'
        parameter name: :string_key, in: :query, required: true
        parameter name: :label, in: :query, required: true
      end
    end

    swagger_path '/vocabularies/{string_key}' do
      operation :get do
        key :description, 'Retrieve vocabulary by string_key'
        parameter name: :string_key, in: :path, type: :string,
                  description: 'String identifier for each vocabulary',
                  pattern: Vocabulary::ALPHANUMERIC_UNDERSCORE_KEY_REGEX,
                  required: true
      end

      operation :patch do
        key :description, 'Update vocabulary'

        parameter name: :string_key, in: :path, type: :string,
                  required: true

        parameter name: :label, in: :query, type: :string,
                  required: false
      end

      operation :delete do
        key :description, 'Delete vocabulary'
        parameter name: :string_key, in: :path, type: :string,
                  required: true
      end
    end

    swagger_path '/vocabularies/{string_key}/custom_fields' do
      operation :post do
        key :description, 'Create a custom field for a vocabulary'
        parameter name: :string_key, in: :path, type: :string,
                  required: true

        parameter name: :field_key, in: :query, type: :string,
                  required: true, pattern: Vocabulary::ALPHANUMERIC_UNDERSCORE_KEY_REGEX

        parameter name: :label, in: :query, type: :string,
                  required: true

        parameter name: :data_type, in: :query, type: :string,
                  required: true, enum: Vocabulary::DATA_TYPES
      end
    end

    swagger_path '/vocabularies/{string_key}/custom_fields/{field_key}' do
      operation :patch do
        parameter name: :string_key, in: :path, type: :string,
                  required: true

        parameter name: :field_key, in: :path, type: :string,
                  required: true

        parameter name: :label, in: :query, type: :string
      end

      operation :delete do
        parameter name: :string_key, in: :path, type: :string,
                  required: true

        parameter name: :field_key, in: :path, type: :string,
                  required: true
      end
    end

    Vocabulary.all.each do |v|
      swagger_path "/vocabularies/#{v.string_key}/terms" do # have to generated for each vocabulary
        operation :get do # search
          key :description, "Search for terms within a #{v.string_key} vocabulary"

          parameter name: :per_page, in: :query, type: :number,
                    default: 20, minimum: 1, maximum: URIService::MAX_PER_PAGE,
                    description: 'Number of results per page'

          parameter name: :page, in: :query, type: :number,
                    default: 1, minimum: 1,
                    description: 'Page of paginated results'

          parameter name: :q, in: :query, type: :string
          parameter name: :uri, in: :query, type: :string,
                    required: true

          parameter name: :pref_label, in: :query, type: :string
          parameter name: :alt_labels, in: :query, type: :array,
                    items: { type: :string }
          parameter name: :authority, in: :query, type: :string
          parameter name: :term_type, in: :query, type: :string

          v.custom_fields.each do |field_key, info_hash|
            parameter name: field_key, in: :query, type: info_hash[:data_type]
          end
        end

        operation :post do
          parameter name: :uuid, in: :query, type: :string,
                    pattern: '\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z'

          parameter name: :pref_label, in: :query, type: :string,
                    required: true

          parameter name: :alt_labels, in: :query, type: :array,
                    'x-uri-service-only-for-term-type': ['external', 'local'],
                    items: { type: :string }

          parameter name: :uri, in: :query, type: :string,
                    required: true, 'x-uri-service-only-for-term-type': ['external']

          parameter name: :authority, in: :query, type: :string

          parameter name: :term_type, in: :query, type: :string,
                    required: true, enum: Term::TERM_TYPES

          v.custom_fields.each do |field_key, info_hash|
            parameter name: field_key, in: :query, type: info_hash[:data_type]
          end
        end
      end

      swagger_path "/vocabularies/#{v.string_key}/terms/{uri}" do
        operation :get do
          parameter name: :uri, in: :path, type: :string, required: true
        end

        operation :patch do
          parameter name: :uri, in: :path, type: :string, required: true
          parameter name: :pref_label, in: :query, type: :string
          parameter name: :alt_labels, in: :query, type: :array,
                    'x-uri-service-only-for-term-type': ['external', 'local'],
                    items: { type: :string }
          parameter name: :authority, in: :query, type: :string

          v.custom_fields.each do |field_key, info_hash|
            parameter name: field_key, in: :query, type: info_hash[:data_type]
          end
        end

        operation :delete do
          parameter name: :uri, in: :path, type: :string, required: true
        end
      end
    end

    def index
      render json: Swagger::Blocks.build_root_json([V1::OpenApiSpecificationController])
    end
  end
end
