class Ability
  include CanCan::Ability
  
  def initialize(user)
    if user.try :has_role?, :admin
      can :manage, :all
    elsif user.try :has_role?,:agent
      can :manage, Command, :user_id => user.id
    elsif user.try :has_role?, :user
      can :read, Server, :user_id => user.id
      can :read, BackupJob do | backup_job|
        backup_job.server.user_id == user.id
      end
      can :read, Profile
      can :read, Include
      can :read, Split
      can :read, Exclude
      can :read, BackupServer
      can :read, Problem do | problem|
        problem.server.user_id == user.id
      end
      can :manage, User, :id => user.id
    else
      # nothing!
    end
  end
=begin  
  authorization do
    role :admin do
      has_permission_on [:users, :servers, 
                         :backup_servers, :profiles, :excludes, :includes, :splits,
                         :roles, :roles_users, :dashboard, :backup_jobs, :commands], 
                         :to => [:manage]
    end
  
    role :guest do
      has_permission_on :sessions, :to => [:new, :create]
      has_permission_on :dashboard, :to => [:index]
    end
  
    role :user do
      includes :guest
      has_permission_on :servers, :to => [:read, :index, :show] do
        if_attribute :user_id => is { user.id }
      end
    
      has_permission_on :backup_jobs, :to => [:read, :index, :show] do
        if_attribute :server => { :user_id => is { user.id }}
      end
    end
  
    role :agent do
      includes :guest
      has_permission_on :commands, :to => [:show, :update] do
        if_attribute :user => is { user }
      end
    
      has_permission_on :commands, :to => [:index]
    end
  end
=end
end