module Api
  module V1
    class ReleasesController < BaseController
      before_action :set_package

      def latest
        release = @package.releases.published.order(published_at: :desc, id: :desc).first!
        render json: { data: release_data(release) }
      end

      def show
        release = @package.releases.published.find_by!(version: params[:version])
        render json: { data: release_data(release) }
      end

      private

      def set_package
        @package = Package.publicly_available.find_by!(name: params[:name])
      end

      def release_data(release)
        {
          package: release.package.name,
          version: release.version,
          license: release.license,
          sources: release.sources,
          targets: release.targets,
          dependencies: release.dependencies,
          files: release.release_files.includes(:package_blob).map do |release_file|
            {
              digest: release_file.package_blob.digest,
              size: release_file.package_blob.byte_size,
              install_path: release_file.install_path,
              permissions: release_file.permissions,
              type: release_file.file_type
            }
          end,
          attestations: release.attestations,
          metadata_signature: release.metadata_signature,
          published_at: release.published_at
        }
      end
    end
  end
end
