class AddLastStartedToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :last_started, :timestamp
  end

  def self.down
    remove_column :servers, :last_started
  end
end
