require 'sinatra'
require 'graphql'
require 'cgi'

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
    description "Find a Post by ID"
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
      todo
    }
  end

  field :todoComplete do
    type types[TodoType]
    argument :id, !types.ID
    argument :status, !types.Boolean
    resolve ->(obj, args, ctx) {
      todos.each do |todo|
        todo.isCompleted = args[:status] if todo[:id] == args[:id]
      end
      todos
    }
  end

  field :todoRemove do
    type types[TodoType]
    argument :id, !types.ID
    resolve ->(obj, args, ctx) {
      todos = todos.reject do |todo|
        todo[:id] == args[:id]
      end
    }
  end
end

Schema = GraphQL::Schema.define do
  query QueryType
  mutation MutationType
end

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
