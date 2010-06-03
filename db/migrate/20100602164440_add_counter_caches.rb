class AddCounterCaches < ActiveRecord::Migration
  def self.up
    add_column :backup_servers, :servers_count, :integer
    add_column :servers, :backup_jobs_count, :integer
    add_column :profiles, :splits_count, :integer
    add_column :profiles, :excludes_count, :integer
    add_column :profiles, :includes_count, :integer
    
    BackupServer.reset_column_information
    BackupServer.find(:all).each do |p|
      BackupServer.update_counters p.id, :servers_count => p.servers.length
    end
    
    Server.reset_column_information
    Server.find(:all).each do |p|
      Server.update_counters p.id, :backup_jobs_count => p.backup_jobs.length
    end
    
    Profile.reset_column_information
    Profile.find(:all).each do |p|
      Profile.update_counters p.id, :splits_count => p.splits.length
      Profile.update_counters p.id, :excludes_count => p.excludes.length
      Profile.update_counters p.id, :includes_count => p.includes.length
    end
    
  end

  def self.down
    remove_column :backup_servers, :servers_count
    remove_column :servers, :backup_jobs_count
    remove_column :profiles, :splits_count
    remove_column :profiles, :excludes_count
    remove_column :profiles, :includes_count
  end
end
