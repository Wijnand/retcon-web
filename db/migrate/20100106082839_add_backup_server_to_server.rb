class AddBackupServerToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :backup_server_id, :integer
  end

  def self.down
    remove_column :servers, :backup_server_id
  end
end
