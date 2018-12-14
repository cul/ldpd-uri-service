class Vocabulary < ApplicationRecord
  has_many :terms, dependent: :destroy

  validates :string_key, presence: true, uniqueness: true, format: {
    with: /\A[a-z]+[a-z0-9_]*\z/,
    message: 'only allows lowercase alphanumeric characters and underscores'
  }
  validates :label,      presence: true

  store :custom_fields, coder: JSON

  def to_api
    as_json(only: [:string_key, :label, :custom_fields])
  end
end
