require 'sinatra'
require 'graphql'
require 'cgi'
require './types'

set :public_folder, Proc.new { File.join(root, "public") }

get '/' do
  erb :index
end

post '/graphql' do
  begin
    payload = JSON.parse(request.body.read)
  rescue
    request.body.rewind
    data = CGI.parse(request.body.read)
    payload = {}
    payload["query"] = data['query'][0]
    payload["variables"] = JSON.parse(data['variables'][0]) rescue {}
    p payload
  end
  Schema.execute(payload['query'], variables: payload['variables']).to_json
end
