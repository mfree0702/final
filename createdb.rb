# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Need to update phonenumber before adding Twilio
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
  String :phonenumber
end
DB.create_table! :places do
    primary_key :id
    String :name
    String :location
    String :max_campers
end
DB.create_table! :reservations do
  primary_key :id
  foreign_key :users_id
  foreign_key :places_id
  Date :start_date
  Date :end_date
  Integer :num_of_campers
end

# Insert initial (seed) data
places_table = DB.from(:places)

places_table.insert(name: "Campsite #1", 
                    location: "Evanston, IL",
                    max_campers: 10,
                    )

places_table.insert(name: "Campsite #2", 
                    location: "Milwaukee, WI",
                    max_campers: 5,
                    )