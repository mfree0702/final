# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt" 
require "geocoder"                                                                     #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

places_table = DB.from(:places)
users_table = DB.from(:users)
reservations_table = DB.from(:reservations)

# put your API credentials here (found on your Twilio dashboard)
# set up a client to talk to the Twilio REST API


# send the SMS from your trial Twilio number to your verified non-Twilio number

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get "/" do 
    @places = places_table.all.to_a
    view "campsites"
end

get "/places/:id" do
    @place = places_table.where(id: params[:id]).to_a[0]
    @reservations = reservations_table.where(places_id: @place[:id])
    @users_table = users_table
    
    @results = Geocoder.search(@place[:location])
    @lat_long = @results.first.coordinates 
    @lat_long = "#{@lat_long[0]},#{@lat_long[1]}"

    view "specific_campsite"
end

get "/places/:id/reservations/new" do
    @place = places_table.where(id: params[:id]).to_a[0]
    @max_campers = @place[:max_campers]
    @var = 1
    view "new_reservation"
end

get "/places/:id/reservations/create" do
    puts params

    twilio_account_sid = ENV['TWILIO_ACCOUNT_SID']
    twilio_auth_token = ENV['TWILIO_AUTH_TOKEN']

    puts "LOOK HERE**"
    puts twilio_account_sid
    puts twilio_auth_token

    client = Twilio::REST::Client.new(twilio_account_sid, twilio_auth_token)

    @place = places_table.where(id: params["id"]).to_a[0]
    reservations_table.insert(places_id: params["id"],
                       users_id: session["user_id"],
                       start_date: params["start_date"],
                       end_date: params["end_date"],
                       num_of_campers: params["num_of_campers"])
    
    # Given Twilio restrictions, the "to" is just my number hard coded. It would normally pull the info from the users table. 
    client.messages.create(
        from: "+18133444977", 
        to: "+16306087300",
        body: "You have successfully reserved #{@place[:name]}"
        )
    
    view "create_reservation"
end

get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts params
    hashed_password = BCrypt::Password.create(params["password"])
    users_table.insert(name: params["name"], email: params["email"], phonenumber: params["phonenumber"], password: hashed_password)
    view "create_user"
end

get "/camps/new" do
    view "new_campsite"
end

post "/camps/create" do
    puts params
    places_table.insert(name: params["name"], 
        location: params["location"], 
        max_campers: params["max_campers"], 
        )
    view "create_campsite"
end

get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    user = users_table.where(email: params["email"]).to_a[0]
    if user && BCrypt::Password::new(user[:password]) == params["password"]
        session["user_id"] = user[:id]
        @current_user = user
        view "create_login"
    else
        view "create_login_failed"
    end
end

get "/logout" do
    session["user_id"] = nil
    @current_user = nil
    view "logout"
end
