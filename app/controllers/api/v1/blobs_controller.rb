require "digest/blake3"

module Api
  module V1
    class BlobsController < BaseController
      MAX_BLOB_SIZE = 256.megabytes

      def create
        token = ENV["ANYNIX_MANAGER_TOKEN"]
        if token.blank?
          return render json: { error: "writes_disabled" }, status: :service_unavailable
        end

        authorization = request.authorization.to_s
        expected = "Bearer #{token}"
        unless ActiveSupport::SecurityUtils.secure_compare(authorization, expected)
          return render json: { error: "unauthorized" }, status: :unauthorized
        end

        if Rails.env.production? && !request.ssl?
          return render json: { error: "https_required" }, status: :forbidden
        end

        upload = params[:file]
        digest = params[:digest]
        size = params[:size]
        unless upload.is_a?(ActionDispatch::Http::UploadedFile) &&
            digest.is_a?(String) && digest.match?(/\A[0-9a-f]{64}\z/) &&
            size.is_a?(String) && size.match?(/\A(?:0|[1-9][0-9]*)\z/) &&
            size.to_i <= MAX_BLOB_SIZE
          return render json: { error: "invalid_blob" }, status: :bad_request
        end

        hasher = Digest::Blake3.new
        byte_size = 0
        while (chunk = upload.read(64.kilobytes))
          byte_size += chunk.bytesize
          if byte_size > MAX_BLOB_SIZE
            return render json: { error: "blob_too_large" }, status: :payload_too_large
          end
          hasher.update(chunk)
        end
        unless byte_size == size.to_i && hasher.hexdigest == digest
          return render json: { error: "blob_mismatch" }, status: :unprocessable_entity
        end

        upload.rewind
        blob = nil
        PackageBlob.transaction do
          blob = PackageBlob.create!(digest: digest, byte_size: byte_size)
          blob.content.attach(io: upload.tempfile, filename: "blob", content_type: "application/octet-stream")
        end
        render json: { data: { digest: blob.digest, size: blob.byte_size } }, status: :created
      rescue ActiveRecord::RecordNotUnique
        render json: { error: "blob_exists" }, status: :conflict
      rescue ActiveRecord::RecordInvalid => error
        raise unless error.record.is_a?(PackageBlob) &&
          error.record.errors.details == { digest: [ { error: :taken, value: digest } ] }

        render json: { error: "blob_exists" }, status: :conflict
      end

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
