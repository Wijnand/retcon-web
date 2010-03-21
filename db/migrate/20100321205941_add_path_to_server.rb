class AddPathToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :path, :string
    Server.all.each do | s |
      s.path = '/'
      s.save
    end
  end

  def self.down
    remove_column :servers, :path
  end
end
