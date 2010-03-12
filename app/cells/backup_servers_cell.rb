class BackupServersCell < Cell::Base
  helper :application
  
  def status
    @backup_servers = BackupServer.all
    render
  end
end
