class SplitsController < ApplicationController
  filter_resource_access
  
  def create
    @profile = Profile.find(params[:profile_id])
    @split = @profile.splits.create(params[:split])
    
    respond_to do |format|
      if @split.save
        flash[:notice] = 'Split was successfully added.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { render :xml => @split, :status => :created, :location => @profile }
      else
        flash[:error] = 'Split was not valid.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { render :xml => @split.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def edit
    @profile = Profile.find(params[:profile_id])
    @split = @profile.splits.find(params[:id])
  end
  
  def update
    @profile = Profile.find(params[:profile_id])
    @split = @profile.splits.find(params[:id])

    respond_to do |format|
      if @split.update_attributes(params[:split])
        flash[:notice] = 'Split was successfully updated.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Split was not valid.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { render :xml => @split.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @profile = Profile.find(params[:profile_id])
    @split = @profile.splits.find(params[:id])
    @split.destroy

    respond_to do |format|
      format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
      format.xml  { head :ok }
    end
  end
end
