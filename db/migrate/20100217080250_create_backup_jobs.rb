class CreateBackupJobs < ActiveRecord::Migration
  def self.up
    create_table :backup_jobs do |t|
      t.integer :backup_server
      t.integer :server
      t.string :status
      t.integer :pid
      t.string :result
      t.text :log

      t.timestamps
    end
  end

  def self.down
    drop_table :backup_jobs
  end
end
