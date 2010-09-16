class UsersController < ApplicationController
  load_and_authorize_resource
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save 
      flash[:notice] = "A new user is born!"
      redirect_to users_path
    else
      render :action => 'new' 
    end
  end
  
  def edit  
    @user = User.accessible_by(current_ability).find(params[:id])
  end  

  def update  
    @user = User.accessible_by(current_ability).find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = "Successfully updated user account."
      redirect_to root_url
    else
      render :action => 'edit'
    end
  end
  
  def index
    @users = User.accessible_by(current_ability).find(:all, :order => 'username', :include => [:backup_server])
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
      format.json  { render :json => @users }
    end
  end
end
