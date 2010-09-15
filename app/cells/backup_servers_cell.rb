class BackupServersCell < Cell::Base
  helper :application
  def status
    @backup_servers = BackupServer.accessible_by(current_ability).find(:all)
    render
  end
end
