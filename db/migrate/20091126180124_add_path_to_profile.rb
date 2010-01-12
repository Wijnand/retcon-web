class AddPathToProfile < ActiveRecord::Migration
  def self.up
    add_column :profiles, :path, :string
  end

  def self.down
    remove_column :profiles, :path
  end
end
