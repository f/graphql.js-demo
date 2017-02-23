require 'sinatra'
require 'graphql'
require 'redis'
require 'cgi'

redis = Redis.new(write_timeout: 0.5)

def random_id
  8.times.collect{[*'a'..'z'].sample}.join
end

Todo = Struct.new("Todo", :id, :text, :isCompleted)

todos = [
  Todo.new(random_id, "Pay the bills.", false),
  Todo.new(random_id, "Go to dentist.", false),
  Todo.new(random_id, "Buy milk.", true)
]

TodoType = GraphQL::ObjectType.define do
  name "Todo"
  description "Todo Item"
  field :id, !types.ID
  field :text, !types.String
  field :isCompleted, !types.Boolean
end

QueryType = GraphQL::ObjectType.define do
  name "Query"
  description "The query root of this schema"

  field :allTodos do
    type types[TodoType]
    description "Find a ToDo by ID"
    resolve ->(obj, args, ctx) { todos }
  end
end

MutationType = GraphQL::ObjectType.define do
  name "Mutation"
  description "The mutation root of this schema"

  field :todoAdd do
    type TodoType
    argument :text, !types.String
    resolve ->(obj, args, ctx) {
      todo = Todo.new(random_id, args[:text], false)
      todos << todo
      Redis.new.publish "graphql.todoAdded", JSON.dump({id: todo.id})
      todo
    }
  end

  field :todoComplete do
    type types[TodoType]
    argument :id, !types.ID
    argument :status, !types.Boolean
    resolve ->(obj, args, ctx) {
      todos.each do |todo|
        if todo[:id] == args[:id]
          todo.isCompleted = args[:status]
          Redis.new.publish "graphql.todoUpdated", JSON.dump({id: args[:id]})
        end
      end
      todos
    }
  end

  field :todoRemove do
    type types[TodoType]
    argument :id, !types.ID
    resolve ->(obj, args, ctx) {
      Redis.new.publish "graphql.todoRemoved", JSON.dump({id: args[:id]})
      todos = todos.reject do |todo|
        todo[:id] == args[:id]
      end
    }
  end
end

SubscriptionType = GraphQL::ObjectType.define do
  name "Subscription"
  description "The subscription root of this schema"

  field :todoAdded do
    type TodoType
    argument :id, !types.ID
    resolve ->(obj, args, ctx) {
      todos.select do |todo|
        if todo[:id] == args[:id]
          todo
        else
          nil
        end
      end.first
    }
  end

  field :todoRemoved do
    type TodoType
    argument :id, !types.ID
    resolve ->(obj, args, ctx) {
      Todo.new(args[:id], "", false)
    }
  end

  field :todoUpdated do
    type TodoType
    argument :id, !types.ID
    resolve ->(obj, args, ctx) {
      todos.select do |todo|
        if todo[:id] == args[:id]
          todo
        else
          nil
        end
      end.first
    }
  end
end

Schema = GraphQL::Schema.define do
  query QueryType
  mutation MutationType
  subscription SubscriptionType
end

get '/' do
  erb :index
end

Stream = Struct.new("Stream", :id, :buffer)
streams = []

get '/graphql' do
  content_type 'text/event-stream'
  id = SecureRandom.hex
  fields = GraphQL::Query.new(Schema, params[:query]).selected_operation.selections.map(&:name)

  stream :keep_open do |buffer|
    buffer << "id: #{id}\n"
    buffer << "event: subscribed\n"
    buffer << "data:\n\n"
    streams << Stream.new(id, buffer)
    redis.subscribe(fields.map{|field| "graphql.#{field}"}) do |on|
      on.message do |channel, data|
        variables = JSON.parse(data) rescue {}
        result = Schema.execute(params[:query], variables: variables)
        streams.each do |str|
          str.buffer << "id: #{str.id}\n"
          str.buffer << "event: #{channel}\n"
          str.buffer << "data: #{JSON.dump(result.to_h)}\n\n"
        end
      end
    end
  end
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
  end
  Schema.execute(payload['query'], variables: payload['variables']).to_json
end
