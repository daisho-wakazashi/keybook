class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :booker, null: false, foreign_key: { to_table: :users }
      t.references :availability, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
