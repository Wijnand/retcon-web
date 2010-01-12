class AddSettingsToBackupServer < ActiveRecord::Migration
  def self.up
    add_column :backup_servers, :zpool, :string
    add_column :backup_servers, :max_backups, :integer
  end

  def self.down
    remove_column :backup_servers, :max_backups
    remove_column :backup_servers, :zpool
  end
end
