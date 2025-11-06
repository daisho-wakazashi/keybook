class CreateAvailabilities < ActiveRecord::Migration[8.1]
  def change
    create_table :availabilities do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false

      t.timestamps
    end

    # Prevent exact duplicates
    add_index :availabilities,
              [ :user_id, :start_time, :end_time ],
              unique: true,
              name: 'index_availabilities_on_unique_slot'
  end
end
