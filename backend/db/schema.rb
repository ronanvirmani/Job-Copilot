# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_18_000000) do
  create_schema "auth"
  create_schema "cron"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "net"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "extensions.pg_net"
  enable_extension "extensions.pg_stat_statements"
  enable_extension "extensions.pgcrypto"
  enable_extension "extensions.uuid-ossp"
  enable_extension "graphql.pg_graphql"
  enable_extension "pg_catalog.pg_cron"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vault.supabase_vault"

  create_table "application_events", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.string "event_type"
    t.jsonb "payload"
    t.datetime "occurred_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_application_events_on_application_id"
  end

  create_table "applications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "company_id", null: false
    t.string "role_title"
    t.string "location"
    t.string "source"
    t.string "job_url"
    t.string "status"
    t.datetime "applied_at"
    t.datetime "last_email_at"
    t.datetime "last_status_change_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_applications_on_company_id"
    t.index ["user_id"], name: "index_applications_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_companies_on_domain"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_contacts_on_company_id"
    t.index ["email"], name: "index_contacts_on_email"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.bigint "contact_id", null: false
    t.string "gmail_message_id"
    t.string "gmail_thread_id"
    t.string "from_addr"
    t.string "to_addr"
    t.string "subject"
    t.text "snippet"
    t.string "classification"
    t.datetime "internal_ts"
    t.jsonb "raw_headers"
    t.jsonb "parts_metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_messages_on_application_id"
    t.index ["contact_id"], name: "index_messages_on_contact_id"
    t.index ["gmail_message_id"], name: "index_messages_on_gmail_message_id"
    t.index ["gmail_thread_id"], name: "index_messages_on_gmail_thread_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "supabase_user_id"
    t.string "email"
    t.text "google_access_token"
    t.text "google_refresh_token"
    t.datetime "token_expires_at"
    t.string "gmail_history_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_gmail_synced_at"
    t.index ["last_gmail_synced_at"], name: "index_users_on_last_gmail_synced_at"
    t.index ["supabase_user_id"], name: "index_users_on_supabase_user_id"
  end

  add_foreign_key "application_events", "applications"
  add_foreign_key "applications", "companies"
  add_foreign_key "applications", "users"
  add_foreign_key "contacts", "companies"
  add_foreign_key "messages", "applications"
  add_foreign_key "messages", "contacts"
end
