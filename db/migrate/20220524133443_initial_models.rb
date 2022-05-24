class InitialModels < ActiveRecord::Migration[7.0]
  def change
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

    create_table :tournaments, id: :bigint do |t|
      t.text :name, null: false, empty: false
      t.text :slug, null: false, empty: false, unique: true
      t.text :url, null: false, empty: false
      t.integer :start_gg_id, null: false, unique: true
      t.timestamps
    end

    create_table :events, id: :bigint do |t|
      t.text :name, null: false, empty: false
      t.belongs_to :tournament, null: false
      t.integer :start_gg_id, null: false, unique: true
      t.timestamps
    end

    create_table :players, id: :bigint do |t|
      t.text :sponsor, null: false, empty: true
      t.text :tag, null: false, empty: false
      t.integer :start_gg_id, null: false, unique: true
      t.integer :points, null: false
      t.timestamps
    end

    create_table :point_changes, id: :bigint do |t|
      t.text :cause, null: false, empty: false
      t.integer :point_change, null: false
      t.belongs_to :player, null: false
      t.belongs_to :event, null: true
      t.timestamps
    end
  end
end
