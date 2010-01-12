require 'spec_helper'

describe BackupServersController do
  describe "routing" do
    it "recognizes and generates #index" do
      { :get => "/backup_servers" }.should route_to(:controller => "backup_servers", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/backup_servers/new" }.should route_to(:controller => "backup_servers", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/backup_servers/1" }.should route_to(:controller => "backup_servers", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/backup_servers/1/edit" }.should route_to(:controller => "backup_servers", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/backup_servers" }.should route_to(:controller => "backup_servers", :action => "create") 
    end

    it "recognizes and generates #update" do
      { :put => "/backup_servers/1" }.should route_to(:controller => "backup_servers", :action => "update", :id => "1") 
    end

    it "recognizes and generates #destroy" do
      { :delete => "/backup_servers/1" }.should route_to(:controller => "backup_servers", :action => "destroy", :id => "1") 
    end
  end
end
