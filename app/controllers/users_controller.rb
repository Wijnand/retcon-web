class UsersController < ApplicationController
  filter_resource_access
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save 
      flash[:notice] = "A new user is born!"
      redirect_to root_url
    else
      render :action => 'new' 
    end
  end
  
  def edit  
    @user = User.find(params[:id])
  end  

  def update  
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = "Successfully updated user account."
      redirect_to root_url
    else
      render :action => 'edit'
    end
  end
  
  def index
    @users = User.find(:all, :order => 'username')
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
      format.json  { render :json => @users }
    end
  end
end
