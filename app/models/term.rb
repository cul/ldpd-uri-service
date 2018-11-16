class Term < ApplicationRecord
  TEMPORARY_URI_BASE = 'temp:'.freeze
  LOCAL     = 'local'.freeze
  TEMPORARY = 'temporary'.freeze
  EXTERNAL  = 'external'.freeze

  TERM_TYPES = [LOCAL, EXTERNAL, TEMPORARY].freeze

  VALID_URI_REGEX = /\A#{URI.regexp}\z/

  SOLR_SUFFIX = {
    'string'  => '_si',
    'number'  => '_ii',
    'boolean' => '_bi'
  }.freeze

  belongs_to :vocabulary

  before_validation :add_uuid, :add_uri, :add_uri_hash, on: :create

  # after_commit :update_solr # Is triggered after successful save/update/destroy.

  validates :vocabulary, :pref_label, :uri, :uri_hash, :uuid, :term_type, presence: true
  validates :term_type, inclusion: { in: TERM_TYPES }
  validate  :uuid_uri_and_term_type_unchanged

  store :custom_fields, coder: JSON

  serialize :alt_label, Array

  def to_solr
    {
      'uuid'          => uuid, # set uuid to be primary field in solr core
      'uri'           => uri,
      'pref_label'    => pref_label,
      'alt_label'     => alt_label, # make sure this is an array
      'term_type'     => term_type,
      'vocabulary'    => vocabulary.string_key,
      'authority'     => authority,
      'custom_fields' => custom_fields # make sure this is a hash
    }.tap do |doc|
      vocabulary.custom_fields.each do |k, v|
        doc["#{k}#{SOLR_SUFFIX[v[:data_type]]}"] = term.custom_field[f]
      end
    end
  end

  private

    def add_uuid
      self.uuid = SecureRandom.uuid unless uuid
    end

    def add_uri
      case term_type
      when nil, ''
        errors.add(:uri, 'Missing term_type prevented uri validation')
      when LOCAL
        if (host = local_uri_host)
          self.uri = "#{host}term/#{self.uuid}"
        end
      when TEMPORARY
        self.uri = URI(TEMPORARY_URI_BASE + Digest::SHA256.hexdigest(self.vocabulary.string_key + self.pref_label)).to_s
      when EXTERNAL
        unless self.uri.match? VALID_URI_REGEX
          errors.add(:uri, 'is not valid')
        end
      end
    end

    def add_uri_hash
      return unless uri
      self.uri_hash = Digest::SHA256.hexdigest(self.uri)
    end

    # Check that uuid, uri and term_type were not changed.
    def uuid_uri_and_term_type_unchanged
      return unless persisted? # skip if object is new or is deleted

      errors.add(:uuid, 'Change of uuid not allowed!') if uuid_changed?
      errors.add(:uri, 'Change of uri not allowed!') if uri_changed?
      errors.add(:term_type, 'Change of term_type not allowed!') if term_type_changed?
    end

    def local_uri_host
      if Rails.application.config.respond_to?(:local_uri_host) && Rails.application.config.local_uri_host.present?
        host = Rails.application.config.local_uri_host.to_s
        host.ends_with?('/') ? host : "#{host}/"
      else
        errors.add(:base, 'Missing Rails.application.config.local_uri_host')
      end
    end

    def update_solr
      # if record was deleted
      # if record was persisted
    end
end