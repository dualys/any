module Api
  module V1
    class PackagesController < BaseController
      def index
        packages = Package.publicly_available.order(:name)
        if params[:query].present?
          query = ActiveRecord::Base.sanitize_sql_like(params[:query])
          packages = packages.where("packages.name ILIKE :query OR packages.summary ILIKE :query", query: "%#{query}%")
        end

        render json: {
          data: packages.limit(50).map { |package| package_summary(package) }
        }
      end

      def show
        package = Package.publicly_available.find_by!(name: params[:name])

        render json: {
          data: {
            **package_summary(package),
            description: package.description,
            homepage: package.homepage,
            repository: package.repository
          }
        }
      end

      private

      def package_summary(package)
        latest_release = package.releases.published.order(published_at: :desc, id: :desc).first

        {
          name: package.name,
          summary: package.summary,
          latest_version: latest_release.version
        }
      end
    end
  end
end
