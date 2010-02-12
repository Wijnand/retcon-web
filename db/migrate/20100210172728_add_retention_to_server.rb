class AddRetentionToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :keep_snapshots, :integer
  end

  def self.down
    remove_column :servers, :keep_snapshots
  end
end
