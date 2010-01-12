class CreateIncludes < ActiveRecord::Migration
  def self.up
    create_table :includes do |t|
      t.integer :profile_id
      t.string :path

      t.timestamps
    end
  end

  def self.down
    drop_table :includes
  end
end
