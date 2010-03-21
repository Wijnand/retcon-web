class RemovePathFromProfile < ActiveRecord::Migration
  def self.up
    remove_column :profiles, :path
  end

  def self.down
    add_column :profiles, :path, :string
  end
end
