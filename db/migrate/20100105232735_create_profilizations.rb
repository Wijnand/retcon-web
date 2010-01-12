class CreateProfilizations < ActiveRecord::Migration
  def self.up
    create_table :profilizations do |t|
      t.integer :server_id
      t.integer :profile_id

      t.timestamps
    end
  end

  def self.down
    drop_table :profilizations
  end
end
