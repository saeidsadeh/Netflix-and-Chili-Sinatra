
require 'pry'
helpers do 
  def current_user 
    User.find(session[:user_id]) if session[:user_id]
  end
end 

# Homepage (Root path)
get '/' do
  erb :index
end

# get '/welcome' do
#   erb :index
# end
# get '/welcome/:name/:job' do
#   @name = params[:name]
#   @job = params[:job]
#   erb :index 
# end



#-------for event posting----------#


get '/events' do
	@events = Event.all
  @events.each do |event|
    registration_count = Registration.where(event_id: event.id).count
    event.capacity -= registration_count
  end
    #Active record object being transferred into a variable.
  if params[:movie_genre] || params[:cuisine]
    @events = @events.where(movie_genre: params[:movie_genre], cuisine: params[:cuisine])
  end
	erb :'/events/index'
end

get '/events/new' do
  @event = Event.new
  erb :'/events/new'
end


#---------- for finding specific event--------#

get '/events/:id' do 
  @event = Event.find(params[:id])
    registration_count = Registration.where(event_id: params[:id]).count
    @event.capacity -= registration_count

  if current_user 
    @registration = Registration.find_by(user_id: session[:user_id],event_id: params[:id])
    if @registration.nil?
      @registration_flag = false
    else
      @registration_flag = true
    end
  end
  # binding.pry
  @comments = @event.comments
  erb :'/event_details/index'
end


post '/events/new' do  #accepting the form data and updating the messages table in db
	@event = Event.new(
		title: params[:title], #params title comes from form. title on left is DB
		address: params[:address],
		capacity: params[:capacity],
		description: params[:description],
		price: params[:price],
		event_date: params[:event_date],
    start_time: params[:start_time],
		image_file: params[:image_file],
    movie_genre: params[:movie_genre],
    cuisine: params[:cuisine]
	)
	if @event.save   
		redirect '/events'
	else
		erb :'events/new'
	end
end

#--------- for messsage posting---------#


# get '/songs/:id' do
#   @song = Song.find params[:id]
#   erb :'songs/show'
# end

post '/events/:id' do
  if params[:commit] == "comment"
      @comment = Comment.new(
      user_id: session[:user_id],
      event_id: params[:id],
      message: params[:message])
      if @comment.save
        redirect '/events/'+params[:id]
      else
        erb :'/event_details/index'
      end
  elsif params[:commit] == "book"
      @registration = Registration.new(
      user_id: session[:user_id],
      event_id: params[:id])
      if @registration.save
        @registration_flag = true
        redirect '/events/'+params[:id]
      else
        @registration_flag = false
        redirect '/events/'+params[:id]
      end
  elsif params[:commit] == "cancel"
      @registration = Registration.find_by(user_id: session[:user_id],event_id: params[:id])
      if @registration.destroy
        @registration_flag = false
        redirect '/events/'+params[:id]
      else
        @registration_flag = true
        redirect '/events/'+params[:id]
      end
  end 
end

#-------  filtering ----------#


post '/events/:id' do
  @comment = Comment.new(
    user_id: session[:user_id],
    event_id: params[:id],
    message: params[:message])
  if @comment.save
    redirect '/events/'+params[:id]
  else
    erb :'/event_details/index'
  end
end


#-------login and registration----------#



before do
  @current_user = User.find(session[:user_id]) if session[:user_id]
  cookies[:page_views] ? cookies[:page_views] = cookies[:page_views].to_i + 1 : cookies[:page_views] = 1
end


get '/login' do
  erb :login
end

post '/login' do
  user = User.find_by(email: params[:email])
  
  if user && user.password_hash == params[:password]  
    session[:user_id] = user.id
    redirect '/'
  else
    erb :login
  end
end


get '/signup' do
  if current_user
    redirect '/'
  else
    erb :signup
  end
end

post '/signup' do
  user = User.new(
    name: params[:name],
    email: params[:email],
    password_hash: params[:password_hash])
  if user.save
    session[:user_id] = user.id
    redirect '/'
  else
    @errors = user.errors
    erb :signup
  end
end

get '/logout' do
  session.clear
  redirect '/'
end

# ---------------myevents-------------

get '/myevents' do
# param = session[:user_id]  
# connection = ActiveRecord::Base.connection
# @events = connection.execute("Select e.title from events e INNER JOIN registrations r on r.event_id = e.id where r.user_id = #{param} ")
# binding.pry
# @events = Event.joins(:registrations).where(user_id: session[:user_id])
@events = Event.joins(:registrations).where("registrations.user_id = ?", session[:user_id])
  @events.each do |event|
    registration_count = Registration.where(event_id: event.id).count
    event.capacity -= registration_count
  end
erb :'/event_details/my_event'
end





















