class AddDiskFreeToBackupServer < ActiveRecord::Migration
  def self.up
    add_column :backup_servers, :disk_free, :string
  end

  def self.down
    remove_column :backup_servers, :disk_free
  end
end
