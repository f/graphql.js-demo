require './utils'

## Models

Todo = Struct.new("Todo", :id, :text, :isCompleted)

## Seed Models
todos = [
  Todo.new(random_id, "Yaka kartlarını bastır.", false),
  Todo.new(random_id, "Oteli ayarla.", false),
  Todo.new(random_id, "Konuşmacıları yedir.", true)
]

## Types

TodoType = GraphQL::ObjectType.define do
  name "Todo"
  description "A todo item to be added into the todo list."
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
    resolve ->(obj, args, ctx) do
      return todos
    end
  end
end

MutationType = GraphQL::ObjectType.define do
  name "Mutation"
  description "The mutation root of this schema"

  field :todoAdd do
    type TodoType
    argument :text, !types.String
    resolve ->(obj, args, ctx) do
      todo = Todo.new(random_id, args[:text], false)
      todos << todo
      return todo
    end
  end

  field :todoComplete do
    type types[TodoType]
    argument :id, !types.ID
    argument :status, !types.Boolean
    resolve ->(obj, args, ctx) do
      todos.each do |todo|
        todo.isCompleted = args[:status] if todo[:id] == args[:id]
      end
      return todos
    end
  end

  field :todoRemove do
    type types[TodoType]
    argument :id, !types.ID
    resolve ->(obj, args, ctx) do
      todos = todos.reject do |todo|
        todo[:id] == args[:id]
      end
      return todos
    end
  end
end

Schema = GraphQL::Schema.define do
  query QueryType
  mutation MutationType
end
