require "test_helper"
require "digest/blake3"
require "tempfile"

module Api
  module V1
    class BlobUploadsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @old_token = ENV["ANYNIX_MANAGER_TOKEN"]
        ENV["ANYNIX_MANAGER_TOKEN"] = "test-manager-token"
        @file = Tempfile.new("blob")
        @file.binmode
        @file.write("abc")
        @file.flush
        @digest = Digest::Blake3.hexdigest("abc")
      end

      teardown do
        ENV["ANYNIX_MANAGER_TOKEN"] = @old_token
        @file.close!
      end

      test "requires a configured manager token" do
        ENV.delete("ANYNIX_MANAGER_TOKEN")
        post "/v1/blobs"
        assert_response :service_unavailable
        ENV["ANYNIX_MANAGER_TOKEN"] = "test-manager-token"
        post "/v1/blobs", headers: { "Authorization" => "Bearer wrong" }
        assert_response :unauthorized
        assert_equal 0, PackageBlob.count
      end

      test "stores a verified candidate without exposing it publicly" do
        post_blob
        assert_response :created
        assert_equal @digest, response.parsed_body.dig("data", "digest")
        assert_equal "abc", PackageBlob.find_by!(digest: @digest).content.download

        get "/v1/blobs/#{@digest}"
        assert_response :not_found

        post_blob
        assert_response :conflict
        assert_equal 1, PackageBlob.count
      end

      test "rejects mismatching hashes and sizes" do
        post_blob(digest: "0" * 64)
        assert_response :unprocessable_entity
        post_blob(size: "4")
        assert_response :unprocessable_entity
        assert_equal 0, PackageBlob.count
      end

      private

      def post_blob(digest: @digest, size: "3")
        file = Rack::Test::UploadedFile.new(@file.path, "application/octet-stream")
        post "/v1/blobs", params: { file: file, digest: digest, size: size },
          headers: { "Authorization" => "Bearer test-manager-token" }
      end
    end
  end
end
