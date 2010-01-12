class CreateExcludes < ActiveRecord::Migration
  def self.up
    create_table :excludes do |t|
      t.integer :profile_id
      t.string :path

      t.timestamps
    end
  end

  def self.down
    drop_table :excludes
  end
end
