class BackupServer < ActiveRecord::Base
  has_many :servers
  
  validates_presence_of :hostname, :zpool, :max_backups
  attr_accessor :in_subnet
  
  def self.available_for(server)
    list = nanite_query("/info/in_subnet?", server)
    recommended = []
    list.each_pair do | server, result |
      recommended.push server if result == true
    end
    available = all
    available.each do | backup_server |
      backup_server.in_subnet = false
      backup_server.in_subnet = true if recommended.include? backup_server.hostname
    end
    available
  end
  
  def to_s
    hostname
  end
  
  def do_nanite(action, payload)
    res = 'undef'
    return [1,'backup server was offline'] unless online?
    Nanite.request(action, payload, :target => "nanite-#{hostname}") do |result |
     key = "nanite-" + hostname
     puts result
     res = result[key]
    end
    while res == 'undef'
      puts "no result yet"
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
    self.class.nanites
  end
  
  def online?
    nanites.include? hostname
  end
  
  def update_disk_space
    if online?
      Nanite.request('/zfs/disk_free', self.zpool, :target => "nanite-#{hostname}") do |result |
       key = "nanite-" + hostname
       puts result
       res = result[key]
       self.disk_free = res
       self.save
      end
    end
  end
  
  def self.nanites
    return [] if Nanite.mapper.nil? or Nanite.mapper.cluster.nil?
    Nanite.mapper.cluster.nanites.map do | nanite |
      nanite[0].sub(/nanite-/,'')
    end
  end
  
  def self.array_to_models(arr)
    find(:all, :conditions => [ "hostname IN (?)", arr])
  end
end
