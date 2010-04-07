class RemoveCrapFromServers < ActiveRecord::Migration
  def self.up
    remove_column :servers, :last_started
  end

  def self.down
    add_column :servers, :last_started, :datetime
  end
end
