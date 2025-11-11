class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_enum :user_role, %w[property_manager tenant]

    create_table :users do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.column :role, :user_role, null: false

      t.timestamps
    end

    add_index :users, :role
  end
end
