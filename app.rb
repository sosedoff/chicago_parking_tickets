require "sinatra"
require "json"
require "./client"

helpers do
  def success_response(object, options = nil)
    JSON.dump(object)
  end

  def error_response(message, status = 400)
    halt(status, success_response(error: message, status: status))
  end
end

before do
  content_type :json, encoding: "utf8"
end

post "/tickets" do
  name  = params[:name].to_s.strip
  plate = params[:plate].to_s.strip
  state = params[:state] || "IL"
  type  = params[:type] || "PAS"

  error_response("name parameter is required")  if name.empty?
  error_response("plate parameter is required") if plate.empty?

  client = ParkingTickets.new

  if params[:unpaid] == "1"
    tickets = client.fetch_unpaid(plate, name, state, type)
  else
    tickets = client.fetch(plate, name, state, type)
  end

  success_response(tickets)
end