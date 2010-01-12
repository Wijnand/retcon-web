class ServersCell < Cell::Base
  def count
    @servers = Server.all
    render
  end
end
