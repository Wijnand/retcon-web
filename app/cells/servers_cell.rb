class ServersCell < Cell::Base
  def overview
    @servers = Server.find(:all, :order => 'hostname')
    render
  end
end
