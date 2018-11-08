class Vocabulary < ApplicationRecord
  validates :string_key, presence: true, uniqueness: true
end
