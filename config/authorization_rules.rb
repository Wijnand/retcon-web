authorization do
  role :admin do
    has_permission_on [:users, :servers, 
                       :backup_servers, :profiles, :excludes, :includes,
                       :roles, :roles_users, :dashboard, :backup_jobs, :commands], 
                       :to => [:index, :show, :new, :create, :edit, :update, :destroy]
  end
  
  role :guest do
    has_permission_on :sessions, :to => [:new, :create]
    has_permission_on :dashboard, :to => [:index]
  end
  
  role :user do
    includes :guest
    has_permission_on :servers, :to => [:show, :index] do
      if_attribute :users => contains { user }
    end
  end
  
  role :agent do
    includes :guest
    has_permission_on :commands, :to => [:show, :index,:update] do
      if_attribute :agent_id => contains { user.id }
    end
  end
end