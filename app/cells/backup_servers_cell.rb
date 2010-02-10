class BackupServersCell < Cell::Base
  helper :application
  
  def count
    @backup_servers = BackupServer.all
    render
  end
  
  def status
    @backup_servers = BackupServer.all
    render
  end
end
