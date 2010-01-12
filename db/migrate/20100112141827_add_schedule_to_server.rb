class AddScheduleToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :window_start, :integer
    add_column :servers, :window_stop, :integer
    add_column :servers, :interval_hours, :integer
  end

  def self.down
    remove_column :servers, :interval_hours
    remove_column :servers, :window_stop
    remove_column :servers, :window_start
  end
end
