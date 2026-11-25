class ReleaseFile < ApplicationRecord
  belongs_to :release
  belongs_to :package_blob
end
