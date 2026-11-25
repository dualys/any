class Release < ApplicationRecord
  belongs_to :package
  has_many :release_files, dependent: :destroy

  scope :published, -> { where.not(published_at: nil) }
end
