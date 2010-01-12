class CreateBackupServers < ActiveRecord::Migration
  def self.up
    create_table :backup_servers do |t|
      t.string :hostname

      t.timestamps
    end
  end

  def self.down
    drop_table :backup_servers
  end
end
