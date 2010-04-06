Factory.define :server do |f|
  f.sequence(:hostname) {|n| "server#{n}.example.com" }
  f.enabled true
  f.ssh_port 22
  f.interval_hours 24
  f.keep_snapshots 30
  f.association :backup_server
  f.path '/'
end

Factory.define :backup_server do | f |
  f.sequence(:hostname) {|n| "backup#{n}.example.com" }
  f.zpool "backup"
  f.max_backups 10
  f.association :user
end

Factory.define :profile do | f |
  f.sequence(:name) {|n| "profile#{n}" }
end

Factory.define :user do | f |
  f.sequence(:username) {|n| "user#{n}" }
  f.password 'testing'
  f.password_confirmation 'testing'
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
end

Factory.define :command do | f |
  f.association :backup_job
  f.command 'ls'
  f.label 'rsync 1'
  f.exitstatus 0
  f.output 'w00t'
end