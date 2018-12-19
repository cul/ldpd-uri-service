class Vocabulary < ApplicationRecord
  ALPHANUMERIC_UNDERSCORE_KEY_REGEX = /\A[a-z]+[a-z0-9_]*\z/
  RESERVED_FIELD_NAMES = %w(
    pref_label alt_label uri uri_hash vocabulary vocabulary_id,
    authority term_type custom_fields uuid created_at updated_at
  ).freeze
  DATA_TYPES = %w(string number boolean).freeze

  has_many :terms, dependent: :destroy

  validates :string_key, presence: true, uniqueness: true, format: {
    with: ALPHANUMERIC_UNDERSCORE_KEY_REGEX,
    message: 'only allows lowercase alphanumeric characters and underscores and must start with a lowercase letter'
  }
  validates :label,      presence: true
  validate :validate_custom_fields

  store :custom_fields, coder: JSON

  def to_api
    as_json(only: [:string_key, :label, :custom_fields])
  end

  def add_custom_field(options = {})
    field_key = options[:field_key]

    if field_key.blank?
      raise 'field_key cannot be blank'
    elsif custom_fields[field_key].present?
      raise 'field_key cannot be added because it\'s already a custom field'
    else
      custom_fields[field_key] = { data_type: options[:data_type], label: options[:label] }
    end
  end

  def update_custom_field(options = {})
    field_key = options[:field_key]

    if field_key.blank?
      raise 'field_key cannot be blank'
    elsif custom_fields[field_key].blank?
      raise 'field_key must be present in order to update custom field'
    elsif options.key?(:label) # if new label given, update label
      custom_fields[field_key][:label] = options[:label]
    end
  end

  def delete_custom_field(field_key)
    if custom_fields.key?(field_key)
      custom_fields.delete(field_key)
    else
      raise 'Cannot delete a custom field that doesn\'t exist'
    end
  end

  private

    def validate_custom_fields
      custom_fields.each do |field_key, info|
        if RESERVED_FIELD_NAMES.include? field_key
          errors.add(:custom_fields, "#{field_key} is a reserved field name and cannot be used")
        end

        unless ALPHANUMERIC_UNDERSCORE_KEY_REGEX.match? field_key
          errors.add(:custom_fields, 'field_key can only contain lowercase alphanumeric characters and underscores and must start with a lowercase letter')
        end

        if info[:label].blank? || info[:data_type].blank?
          errors.add(:custom_fields, 'each custom_field must have a label and data_type defined')
        end

        unless DATA_TYPES.include? info[:data_type]
          errors.add(:custom_fields, 'data_type must be one of string, number or boolean')
        end
      end
    end
end
