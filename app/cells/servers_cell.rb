class ServersCell < Cell::Base
  def overview
    @servers = Server.all
    render
  end
end
