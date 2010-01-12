class AddLastBackupToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :last_backup, :timestamp
  end

  def self.down
    remove_column :servers, :last_backup
  end
end
