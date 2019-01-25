class Term < ApplicationRecord
  TEMPORARY_URI_BASE = 'temp:'.freeze
  LOCAL     = 'local'.freeze
  TEMPORARY = 'temporary'.freeze
  EXTERNAL  = 'external'.freeze

  TERM_TYPES = [LOCAL, EXTERNAL, TEMPORARY].freeze

  belongs_to :vocabulary

  before_validation :set_uuid, :set_uri, :set_uri_hash, on: :create
  before_save :cast_custom_fields
  after_commit :update_solr # Is triggered after successful save/update/destroy.

  validates :vocabulary, :pref_label, :uri, :uri_hash, :uuid, :term_type, presence: true
  validates :term_type, inclusion: { in: TERM_TYPES, message: 'is not valid: %{value}' }, allow_nil: true
  validates :uri,  format: { with: /\A#{URI.regexp}\z/ },
                   if: Proc.new { |t| t.uri? && (t.term_type == LOCAL || t.term_type == EXTERNAL) }
  validates :uri_hash, uniqueness: { scope: :vocabulary, message: 'unique check failed. This uri already exists in this vocabulary.' }
  validates :uuid, format: { with: /\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z/ }, allow_nil: true
  validates :alt_label, absence: { message: 'is not allowed for temporary terms' }, if: Proc.new { |t| t.term_type == TEMPORARY }
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

  private
    def cast_custom_fields
      custom_fields.each do |k, v|
        next if v.nil?
        raise "custom_field #{k} is not a valid custom field" unless vocabulary.custom_fields.keys.include?(k)

        case vocabulary.custom_fields[k][:data_type]
        when 'string'
          raise "custom_field #{k} must be a string" unless v.is_a?(String)
        when 'integer'
          if valid_integer?(v)
            custom_fields[k] = v.to_i if v.is_a?(String)
          else
            raise "custom_field #{k} must be an integer"
          end
        when 'boolean'
          if valid_boolean?(v)
            custom_fields[k] = (v == 'true') ? true : false if v.is_a?(String)
          else
            raise "custom_field #{k} must be a boolean"
          end
        end
      end
    end

    def validate_custom_fields
      custom_fields.each do |k, v|
        next if v.nil?

        if vocabulary.custom_fields.keys.include?(k)
          case vocabulary.custom_fields[k][:data_type]
          when 'string'
            errors.add(:custom_field, "#{k} must be a string") unless v.is_a?(String)
          when 'integer'
            errors.add(:custom_field, "#{k} must be a (non-zero padded) integer") unless valid_integer?(v)
          when 'boolean'
            errors.add(:custom_field, "#{k} must be a boolean") unless valid_boolean?(v)
          end
        else
          errors.add(:custom_field, "#{k} is not a valid custom field.")
        end
      end
    end

    def valid_integer?(v)
      v.is_a?(Integer) || (v.is_a?(String) && /\A[+-]?[1-9]\d*\z/.match(v))
    end

    def valid_boolean?(v)
      (!!v == v) || (v.is_a?(String) && /\A(true|false)\z/.match(v))
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
