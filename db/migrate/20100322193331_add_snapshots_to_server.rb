class AddSnapshotsToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :snapshots, :text
  end

  def self.down
    remove_column :servers, :snapshots
  end
end
