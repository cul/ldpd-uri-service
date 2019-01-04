class Term < ApplicationRecord
  TEMPORARY_URI_BASE = 'temp:'.freeze
  LOCAL     = 'local'.freeze
  TEMPORARY = 'temporary'.freeze
  EXTERNAL  = 'external'.freeze

  TERM_TYPES = [LOCAL, EXTERNAL, TEMPORARY].freeze

  belongs_to :vocabulary

  before_validation :set_uuid, :set_uri, :set_uri_hash, on: :create

  after_commit :update_solr # Is triggered after successful save/update/destroy.

  validates :vocabulary, :pref_label, :uri, :uri_hash, :uuid, :term_type, presence: true
  validates :term_type, inclusion: { in: TERM_TYPES, message: 'is not valid: %{value}' }, allow_nil: true
  validates :uri,  format: { with: /\A#{URI.regexp}\z/ },
                   if: Proc.new { |t| t.uri? && (t.term_type == LOCAL || t.term_type == EXTERNAL) }
  validates :uri_hash, uniqueness: { scope: :vocabulary, message: 'unique check failed. This uri already exists in this vocabulary.' }
  validates :uuid, format: { with: /\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z/ }, allow_nil: true
  validates :alt_label, absence: true, if: Proc.new { |t| t.term_type == TEMPORARY }
  validate  :uuid_uri_and_term_type_unchanged, :pref_label_unchanged_for_temp_term, :validate_custom_fields

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

  def set_custom_field(field, value)
    self.custom_fields[field] = value
  end

  def already_exists?
    errors.added?(:uri, :uniquness) || errors.added?(:uri_hash, :uniqueness)
  end

  private

    def validate_custom_fields
      custom_fields.each do |k, _|
        # TODO: Validate data_type.
        unless vocabulary.custom_fields.keys.include?(k)
          errors.add(:custom_field, "#{k} is not a valid custom field.")
        end
      end
    end

    def set_uuid
      if new_record?
        self.uuid = SecureRandom.uuid unless uuid
      else
        raise StandardError, 'Cannot set uuid if record has already been persisted.'
      end
    end

    def set_uri
      case term_type
      when LOCAL
        self.uri = "#{URIService.local_uri_host}term/#{self.uuid}"
      when TEMPORARY
        self.uri = URI(TEMPORARY_URI_BASE + Digest::SHA256.hexdigest(self.vocabulary.string_key + self.pref_label)).to_s
      end
    end

    def set_uri_hash
      self.uri_hash = Digest::SHA256.hexdigest(self.uri) if uri
    end

    # Check that uuid, uri and term_type were not changed.
    def uuid_uri_and_term_type_unchanged
      return unless persisted? # skip if object is new or is deleted

      errors.add(:uuid, 'Change of uuid not allowed!') if uuid_changed?
      errors.add(:uri, 'Change of uri not allowed!') if uri_changed?
      errors.add(:term_type, 'Change of term_type not allowed!') if term_type_changed?
    end

    # Check that pref_label has not been changed if temporary term
    def pref_label_unchanged_for_temp_term
      return unless persisted? && term_type == TEMPORARY # skip if object is new or is deleted

      errors.add(:pref_label, 'cannot be updated for temp terms') if pref_label_changed?
    end

    def update_solr # If this is unsuccessful the solr core will be out of sync
      if self.destroyed?
        URIService.solr.delete(uuid)
      elsif self.persisted?
        URIService.solr.add(to_solr)
      end
    end
end
