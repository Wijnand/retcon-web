class CreateSplits < ActiveRecord::Migration
  def self.up
    create_table :splits do |t|
      t.string :path
      t.integer :profile_id

      t.timestamps
    end
  end

  def self.down
    drop_table :splits
  end
end
