class CreatePackageRegistry < ActiveRecord::Migration[8.1]
  def change
    create_table :packages do |t|
      t.string :name, null: false
      t.text :summary
      t.text :description
      t.string :homepage
      t.string :repository
      t.timestamps
    end
    add_index :packages, :name, unique: true

    create_table :releases do |t|
      t.references :package, null: false, foreign_key: true
      t.string :version, null: false
      t.string :license
      t.jsonb :sources, null: false, default: []
      t.jsonb :targets, null: false, default: []
      t.jsonb :dependencies, null: false, default: []
      t.jsonb :attestations, null: false, default: []
      t.jsonb :metadata_signature
      t.datetime :published_at
      t.timestamps
    end
    add_index :releases, %i[package_id version], unique: true
    add_index :releases, %i[package_id published_at]

    create_table :package_blobs do |t|
      t.string :digest, null: false
      t.bigint :byte_size, null: false
      t.timestamps
    end
    add_index :package_blobs, :digest, unique: true

    create_table :release_files do |t|
      t.references :release, null: false, foreign_key: true
      t.references :package_blob, null: false, foreign_key: true
      t.string :install_path, null: false
      t.integer :permissions, null: false
      t.string :file_type, null: false
      t.timestamps
    end

    create_table :signing_keys do |t|
      t.string :fingerprint, null: false
      t.string :algorithm, null: false
      t.text :public_key, null: false
      t.string :status, null: false, default: "active"
      t.jsonb :roles, null: false, default: []
      t.datetime :valid_from
      t.datetime :valid_until
      t.timestamps
    end
    add_index :signing_keys, :fingerprint, unique: true

    create_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false
      t.index :key, unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }
      t.datetime :created_at, null: false
      t.index %i[blob_id record_type record_id name], unique: true,
        name: "index_active_storage_attachments_uniqueness"
    end
  end
end
