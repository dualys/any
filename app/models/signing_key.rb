class SigningKey < ApplicationRecord
  validates :fingerprint, :algorithm, :public_key, :status, presence: true
  validates :fingerprint, uniqueness: true
end
