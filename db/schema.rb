# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_25_131700) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id", "record_type", "record_id", "name"], name: "index_active_storage_attachments_uniqueness", unique: true
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "package_blobs", force: :cascade do |t|
    t.string "digest", null: false
    t.bigint "byte_size", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["digest"], name: "index_package_blobs_on_digest", unique: true
  end

  create_table "packages", force: :cascade do |t|
    t.string "name", null: false
    t.text "summary"
    t.text "description"
    t.string "homepage"
    t.string "repository"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_packages_on_name", unique: true
  end

  create_table "release_files", force: :cascade do |t|
    t.bigint "release_id", null: false
    t.bigint "package_blob_id", null: false
    t.string "install_path", null: false
    t.integer "permissions", null: false
    t.string "file_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_blob_id"], name: "index_release_files_on_package_blob_id"
    t.index ["release_id"], name: "index_release_files_on_release_id"
  end

  create_table "releases", force: :cascade do |t|
    t.bigint "package_id", null: false
    t.string "version", null: false
    t.string "license"
    t.jsonb "sources", default: [], null: false
    t.jsonb "targets", default: [], null: false
    t.jsonb "dependencies", default: [], null: false
    t.jsonb "attestations", default: [], null: false
    t.jsonb "metadata_signature"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_id", "published_at"], name: "index_releases_on_package_id_and_published_at"
    t.index ["package_id", "version"], name: "index_releases_on_package_id_and_version", unique: true
    t.index ["package_id"], name: "index_releases_on_package_id"
  end

  create_table "signing_keys", force: :cascade do |t|
    t.string "fingerprint", null: false
    t.string "algorithm", null: false
    t.text "public_key", null: false
    t.string "status", default: "active", null: false
    t.jsonb "roles", default: [], null: false
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fingerprint"], name: "index_signing_keys_on_fingerprint", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "release_files", "package_blobs"
  add_foreign_key "release_files", "releases"
  add_foreign_key "releases", "packages"
end
