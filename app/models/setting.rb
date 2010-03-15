class Setting < ActiveRecord::Base
  validates_presence_of :name, :value
  
  def self.[](thing=nil)
    find(:last, :conditions => { :name => thing}).value
  end
  
end
