Factory.define :server do |f|
  f.sequence(:hostname) {|n| "server#{n}.example.com" }
  f.enabled true
  f.interval_hours 24
  f.keep_snapshots 30
  f.association :backup_server
end

Factory.define :backup_server do | f |
  f.sequence(:hostname) {|n| "backup#{n}.example.com" }
  f.zpool "backup"
  f.max_backups 10
end

Factory.define :profile do | f |
  f.sequence(:name) {|n| "profile#{n}" }
  f.path  '/'
end

Factory.define :exclude do | f |
  f.sequence(:path) {|n| "/exclude/#{n}" }
  f.association :profile
end

Factory.define :include do | f |
  f.sequence(:path) {|n| "/include/#{n}" }
  f.association :profile
end

Factory.define :backup_job do | f |
  f.association :backup_server
  f.association :server
  f.status 'running'
  f.pid '1028'
end