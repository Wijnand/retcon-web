class BackupServer < ActiveRecord::Base
  has_many :servers
  
  validates_presence_of :hostname, :zpool, :max_backups
  
  def self.available_for(server)
    list = nanite_query("/info/in_subnet?", server)
    available = []
    list.each_pair do | server, result |
      available.push server if result == true
    end
    array_to_models available
  end
  
  def to_s
    hostname
  end
  
  private
  def do_nanite(action, payload)
    res = 'undef'
    return nil unless nanites["nanite-#{hostname}"]
    Nanite.request(action, payload, :target => hostname) do |result |
     key = "nanite-" + hostname
     res = result[key]
    end
    while res == 'undef'
      sleep 0.1
    end
    return res
  end
  
  def self.nanite_query(action, payload)
    res = 'undef'
    servers = {}
    return servers if nanites.size == 0
    Nanite.request(action, payload, :selector => :all) do | result |
      result.each_pair do | key, value |
        # Strip the nanite- prefix in the hash key
        new_key = key.sub(/nanite-/,'')
        servers[new_key] = value
      end
      res = servers
    end
    while res == 'undef'
      sleep 0.1
    end
    return res
  end
  
  def nanites
    Nanite.mapper.cluster.nanites
  end
  
  def self.nanites
    Nanite.mapper.cluster.nanites
  end
  
  def self.array_to_models(arr)
    find(:all, :conditions => [ "hostname IN (?)", arr])
  end
end
