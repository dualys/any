class PackageBlob < ApplicationRecord
  has_one_attached :content
  has_many :release_files, dependent: :restrict_with_error

  validates :digest, format: { with: /\A[a-f0-9]{64}\z/ }, uniqueness: true
  validates :byte_size, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
