# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140407130751) do

  create_table "admins", force: true do |t|
    t.string  "admin_name",     limit: 50,             null: false
    t.string  "admin_email_id", limit: 50,             null: false
    t.string  "admin_password", limit: 50,             null: false
    t.string  "admin_token",    limit: 50,             null: false
    t.integer "admin_status",   limit: 2,  default: 0, null: false
  end

  create_table "city_everything_elses", force: true do |t|
    t.string  "city",                   limit: 100, null: false
    t.integer "no_of_solar_homes",                  null: false
    t.string  "3rd_party_owned_system", limit: 100, null: false
    t.integer "average_system_size",                null: false
  end

  create_table "city_inverter_brands", force: true do |t|
    t.string  "city",              limit: 100, null: false
    t.string  "inverter_brands",   limit: 100, null: false
    t.integer "no_of_solar_homes",             null: false
  end

  create_table "city_panel_brands", force: true do |t|
    t.string  "city",              limit: 100, null: false
    t.string  "panel_brands",      limit: 100, null: false
    t.integer "no_of_solar_homes",             null: false
  end

  create_table "city_top_installers", force: true do |t|
    t.string  "city",              limit: 100, null: false
    t.string  "installers",        limit: 100, null: false
    t.integer "no_of_solar_homes",             null: false
  end

  create_table "companies", force: true do |t|
    t.string "name"
    t.string "email"
    t.string "address"
    t.string "zip"
    t.string "city"
    t.string "state"
    t.string "contact"
  end

  create_table "contacts", force: true do |t|
    t.string "full_name",    limit: 100, null: false
    t.string "email",        limit: 100, null: false
    t.string "mobile_phone", limit: 20
    t.string "about",        limit: 200, null: false
    t.text   "message",                  null: false
  end

  create_table "speed_on_data", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "speedon_data", id: false, force: true do |t|
    t.string "ZIP5",                  limit: 50, null: false
    t.string "ZIP4",                  limit: 50, null: false
    t.string "riskiq3",               limit: 50, null: false
    t.string "delineate",             limit: 50, null: false
    t.string "AIQ_Green",             limit: 50, null: false
    t.string "IncomeIQ_Dol",          limit: 50, null: false
    t.string "DebtRatio",             limit: 50, null: false
    t.string "Premoves",              limit: 50, null: false
    t.string "Age_z4",                limit: 50, null: false
    t.string "ResidenceTime_z4",      limit: 50, null: false
    t.string "MortgageAmount_z4",     limit: 50, null: false
    t.string "PersonsatResidence_z4", limit: 50, null: false
    t.string "Homeowner_pct_z4",      limit: 50, null: false
    t.string "Loantovalue_z4",        limit: 50, null: false
    t.string "IncomeIQ_plus_z4",      limit: 50, null: false
    t.string "AIQ_Green_plus_z4",     limit: 50, null: false
    t.string "Homeequity_pc_z4",      limit: 50, null: false
    t.string "NumberofadultsinZip4",  limit: 50, null: false
    t.string "State2",                limit: 50, null: false
  end

  create_table "user_purchases", primary_key: "transaction_id", force: true do |t|
    t.integer   "user_id",                            limit: 8,               null: false
    t.string    "address",                            limit: 200,             null: false
    t.integer   "prev_check",                                     default: 0, null: false
    t.integer   "zip",                                                        null: false
    t.string    "owner_name",                         limit: 100
    t.string    "mailing_address",                    limit: 200
    t.integer   "owner_occupied_indicator",           limit: 2
    t.timestamp "last_sale_date"
    t.integer   "last_sale_price",                    limit: 8
    t.integer   "last_sale_price_per_sqr_ft"
    t.string    "land_use_code",                      limit: 50
    t.string    "zoning",                             limit: 50
    t.integer   "no_of_residential_per_common_units"
    t.integer   "gross_area",                         limit: 8
    t.integer   "living_area",                        limit: 8
    t.integer   "no_of_bedrooms"
    t.integer   "no_of_bathrooms"
    t.integer   "year_built"
    t.integer   "pool",                               limit: 2
    t.string    "heat_type",                          limit: 100
    t.string    "heat_fuel",                          limit: 100
    t.string    "roof_type",                          limit: 100
    t.string    "roof_shape",                         limit: 100
    t.string    "roof_material",                      limit: 100
    t.string    "roof_frame",                         limit: 200
    t.string    "condition",                          limit: 50
    t.integer   "no_of_stories",                      limit: 8
    t.date      "last_purchase_date"
    t.integer   "status",                             limit: 2,               null: false
    t.integer   "zip4"
    t.string    "riskiq3",                            limit: 100
    t.string    "delineate",                          limit: 100
    t.string    "AIQ_Green",                          limit: 100
    t.string    "IncomeIQ_Dol",                       limit: 100
    t.string    "DebtRatio",                          limit: 100
    t.string    "Premoves",                           limit: 100
    t.integer   "Age_z4"
    t.string    "ResidenceTime_z4",                   limit: 100
    t.string    "MortgageAmount_z4",                  limit: 100
    t.string    "PersonsatResidence_z4",              limit: 100
    t.string    "HomeOwner_pct_z4",                   limit: 100
    t.string    "LoantoValue_z4",                     limit: 100
    t.string    "IncomeIQ_plus_z4",                   limit: 100
    t.string    "AIQ_Green_plus_z4",                  limit: 100
    t.string    "Homeequity_pc_z4",                   limit: 100
    t.string    "NumberofadultsinZip4",               limit: 100
    t.string    "State2",                             limit: 50
  end

  add_index "user_purchases", ["user_id"], name: "user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "first_name",         limit: 100
    t.string   "last_name",          limit: 100
    t.string   "company_name",       limit: 100
    t.string   "company_address",    limit: 200
    t.string   "zip",                limit: 100
    t.string   "city",               limit: 100
    t.string   "state",              limit: 100
    t.string   "title",              limit: 100
    t.string   "company_email_id",   limit: 200
    t.string   "mobile_phone",       limit: 20
    t.string   "office_phone",       limit: 20
    t.string   "cust_id",            limit: 100
    t.string   "subscription_id",    limit: 100
    t.float    "monthly_charge",                 default: 99.0, null: false
    t.float    "house_charge",                   default: 3.0,  null: false
    t.integer  "credits",                        default: 0
    t.integer  "card_exp_year"
    t.integer  "card_exp_month"
    t.integer  "card_no",            limit: 8
    t.string   "current_period_end", limit: 50
    t.integer  "payment_status",     limit: 2,   default: 0,    null: false
    t.string   "verification_token", limit: 200
    t.integer  "role",               limit: 2,   default: 0
    t.string   "password",           limit: 200
    t.integer  "active_status",      limit: 2,   default: 0
    t.date     "last_activity"
    t.datetime "registration_date"
    t.date     "forgot_pass_date"
  end

  create_table "utilitytables", force: true do |t|
    t.integer "zip",                      null: false
    t.integer "comp_id",                  null: false
    t.string  "utility_type", limit: 200, null: false
    t.string  "utility",      limit: 200, null: false
    t.string  "state",        limit: 200, null: false
    t.string  "county",       limit: 200, null: false
    t.string  "city",         limit: 200, null: false
  end

  create_table "zip_everything_elses", force: true do |t|
    t.integer "zip",                    null: false
    t.integer "no_of_solar_homes",      null: false
    t.integer "3rd_party_owned_system", null: false
    t.float   "average_system_size",    null: false
  end

  create_table "zip_inverter_brands", force: true do |t|
    t.integer "zip",                           null: false
    t.string  "inverter_brands",   limit: 100, null: false
    t.integer "no_of_solar_homes",             null: false
  end

  create_table "zip_panel_brands", force: true do |t|
    t.integer "zip",                           null: false
    t.string  "panel_brands",      limit: 100, null: false
    t.integer "no_of_solar_homes",             null: false
  end

  create_table "zip_top_installers", force: true do |t|
    t.integer "zip",                           null: false
    t.string  "installers",        limit: 100, null: false
    t.integer "no_of_solar_homes",             null: false
  end

end
