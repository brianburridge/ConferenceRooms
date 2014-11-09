class CreateConferenceRooms < ActiveRecord::Migration
  def change
    create_table :conference_rooms do |t|
      t.string :name
      t.string :location
      t.integer :sq_ft
      t.string :photo
      t.text :description
      t.references :user, index: true

      t.timestamps
    end
  end
end
