# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100321222901) do

  create_table "backup_jobs", :force => true do |t|
    t.integer  "backup_server_id"
    t.integer  "server_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "backup_jobs", ["status"], :name => "index_backup_jobs_on_status"

  create_table "backup_servers", :force => true do |t|
    t.string   "hostname"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "zpool"
    t.integer  "max_backups"
    t.string   "disk_free"
  end

  create_table "commands", :force => true do |t|
    t.integer  "backup_job_id"
    t.integer  "exitstatus"
    t.text     "output"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "label"
    t.text     "command"
  end

  create_table "excludes", :force => true do |t|
    t.integer  "profile_id"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "includes", :force => true do |t|
    t.integer  "profile_id"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "problems", :force => true do |t|
    t.integer  "server_id"
    t.integer  "backup_server_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "profiles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "profilizations", :force => true do |t|
    t.integer  "server_id"
    t.integer  "profile_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "servers", :force => true do |t|
    t.string   "hostname"
    t.boolean  "enabled",          :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "connect_to"
    t.integer  "ssh_port"
    t.integer  "backup_server_id"
    t.datetime "last_started"
    t.integer  "window_start"
    t.integer  "window_stop"
    t.integer  "interval_hours"
    t.integer  "keep_snapshots"
    t.string   "path"
    t.integer  "usage"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "email"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "backup_server_id"
  end

end
