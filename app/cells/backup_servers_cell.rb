class BackupServersCell < Cell::Base
  def count
    @backup_servers = BackupServer.all
    render
  end
end
