require "test_helper"

module Api
  module V1
    class PackagesControllerTest < ActionDispatch::IntegrationTest
      test "package search only returns packages with published releases" do
        public_package = Package.create!(name: "visible", summary: "A public package")
        public_package.releases.create!(version: "1.0.0", published_at: Time.current)
        Package.create!(name: "draft", summary: "Not published")

        get "/v1/packages", params: { query: "public" }

        assert_response :success
        assert_equal [ "visible" ], response.parsed_body.dig("data").map { |package| package["name"] }
      end

      test "package show does not expose a package with only unpublished releases" do
        package = Package.create!(name: "draft")
        package.releases.create!(version: "1.0.0")

        get "/v1/packages/#{package.name}"

        assert_response :not_found
        assert_equal "not_found", response.parsed_body["error"]
      end

      test "release endpoints do not expose unpublished versions" do
        package = Package.create!(name: "visible")
        package.releases.create!(version: "1.0.0", published_at: Time.current)
        package.releases.create!(version: "2.0.0")

        get "/v1/packages/#{package.name}/releases/2.0.0"

        assert_response :not_found
      end

      test "latest release returns the most recently published release" do
        package = Package.create!(name: "visible")
        package.releases.create!(version: "1.0.0", published_at: 1.day.ago)
        package.releases.create!(
          version: "2.0.0",
          license: "MIT",
          targets: [ { os: "linux", architecture: "x86_64" } ],
          published_at: Time.current
        )

        get "/v1/packages/#{package.name}/releases/latest"

        assert_response :success
        assert_equal "2.0.0", response.parsed_body.dig("data", "version")
        assert_equal "MIT", response.parsed_body.dig("data", "license")
      end

      test "blob endpoint redirects only to content referenced by a public release" do
        package = Package.create!(name: "visible")
        release = package.releases.create!(version: "1.0.0", published_at: Time.current)
        blob = PackageBlob.create!(digest: "a" * 64, byte_size: 4)
        blob.content.attach(io: StringIO.new("data"), filename: "payload.bin")
        release.release_files.create!(
          package_blob: blob,
          install_path: "bin/payload",
          permissions: 0o755,
          file_type: "executable"
        )

        get "/v1/blobs/#{blob.digest}"

        assert_response :redirect
        assert_includes response.location, "/rails/active_storage/blobs/redirect/"
      end

      test "key endpoint returns public key metadata" do
        fingerprint = "b" * 64
        SigningKey.create!(
          fingerprint: fingerprint,
          algorithm: "ed25519",
          public_key: "public-key-data",
          status: "revoked",
          roles: [ "release" ]
        )

        get "/v1/keys/#{fingerprint}"

        assert_response :success
        assert_equal "public-key-data", response.parsed_body.dig("data", "public_key")
        assert_equal "revoked", response.parsed_body.dig("data", "status")
      end
    end
  end
end
