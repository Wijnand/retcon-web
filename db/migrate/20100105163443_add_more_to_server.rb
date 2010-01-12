class AddMoreToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :connect_to, :string
  end

  def self.down
    remove_column :servers, :connect_to
  end
end
