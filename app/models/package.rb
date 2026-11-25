class Package < ApplicationRecord
  has_many :releases, dependent: :destroy

  scope :publicly_available, -> {
    where(id: Release.where.not(published_at: nil).select(:package_id))
  }
end
