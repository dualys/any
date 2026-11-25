module Api
  module V1
    class BlobsController < BaseController
      def show
        blob = PackageBlob.joins(release_files: :release)
          .merge(Release.published)
          .distinct
          .find_by!(digest: params[:blake3])

        raise ActiveRecord::RecordNotFound unless blob.content.attached?
        raise ActiveRecord::RecordNotFound unless blob.content.blob.byte_size == blob.byte_size

        redirect_to rails_blob_path(blob.content, disposition: "attachment")
      end
    end
  end
end
