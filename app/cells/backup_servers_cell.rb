class BackupServersCell < Cell::Base
  helper :application
  
  def status
    @backup_servers = BackupServer.find(:all)
    render
  end
end
