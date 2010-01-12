class AddPortToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :ssh_port, :integer
  end

  def self.down
    remove_column :servers, :ssh_port
  end
end
