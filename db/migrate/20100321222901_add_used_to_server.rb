class AddUsedToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :usage, :integer
  end

  def self.down
    remove_column :servers, :usage
  end
end
