class Vocabulary < ApplicationRecord
  has_many :term, dependent: :destroy

  validates :string_key, presence: true, uniqueness: true
  validates :label,      presence: true

  store :custom_fields, coder: JSON

  def to_api
    as_json(only: [:string_key, :label, :custom_fields])
  end
end
