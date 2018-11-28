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

  after_commit :update_solr # Is triggered after successful save/update/destroy.

  validates :vocabulary, :pref_label, :uri, :uri_hash, :uuid, :term_type, presence: true
  validates :term_type, inclusion: { in: TERM_TYPES }
  validate  :uuid_uri_and_term_type_unchanged

  store :custom_fields, coder: JSON

  serialize :alt_label, Array

  def to_solr
    {
      'uuid'          => uuid,
      'uri'           => uri,
      'pref_label'    => pref_label,
      'alt_label'     => alt_label,
      'term_type'     => term_type,
      'vocabulary'    => vocabulary.string_key,
      'authority'     => authority,
      'custom_fields' => custom_fields.to_json
    }.tap do |doc|
      vocabulary.custom_fields.each do |k, v|
        doc["#{k}#{URIService.solr_suffix(v[:data_type])}"] = self.custom_fields[k]
      end
    end
  end

  def add_custom_field(field, value)
    if vocabulary.nil?
      errors.add(:custom_field, 'cannot add custom field until vocabulary relationship has been set')
    elsif !vocabulary.custom_fields.keys.include?(field)
      errors.add(:custom_field, "cannot add #{field} because it is not defined by parent vocabulary")
    else
      self.custom_fields[field] = value
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

    def update_solr # If this is unsuccessful the solr core will be out of sync
      if self.destroyed?
        URIService.solr.delete(uuid)
      elsif self.persisted?
        URIService.solr.add(to_solr)
      end
    end
end
