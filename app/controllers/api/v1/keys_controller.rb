module Api
  module V1
    class KeysController < BaseController
      def show
        key = SigningKey.find_by!(fingerprint: params[:fingerprint])

        render json: {
          data: {
            fingerprint: key.fingerprint,
            algorithm: key.algorithm,
            public_key: key.public_key,
            status: key.status,
            roles: key.roles,
            valid_from: key.valid_from,
            valid_until: key.valid_until
          }
        }
      end
    end
  end
end
