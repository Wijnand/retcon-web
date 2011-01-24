class Removecountercaches < ActiveRecord::Migration
  def self.up
    remove_column :backup_servers, :servers_count
    remove_column :servers, :backup_jobs_count
    remove_column :profiles, :splits_count
    remove_column :profiles, :excludes_count
    remove_column :profiles, :includes_count
  end

  def self.down
  end
end
