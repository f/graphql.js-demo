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
  description 'Todo her bir yapılacak iştir.'
  field :id, !types.ID, 'Benzersiz kimlik numarası.'
  field :text, !types.String, 'Yapılacak işin metni.'
  field :isCompleted, !types.Boolean, 'Yapılacak iş tamamlandı mı?'
end

# Base Types

QueryType = GraphQL::ObjectType.define do
  name "Query"
  description 'Uygulama şemasının sorgu köküdür. Bu kök üzerinden sorgu yapılır.'

  field :allTodos do
    type types[TodoType]
    description "Tüm yapılacak işleri listeler."
    resolve ->(obj, args, ctx) do
      return todos
    end
  end
end

MutationType = GraphQL::ObjectType.define do
  name "Mutation"
  description "Uygulama şemasının mutasyon köküdür. Bu kök üzerinden mutasyon yapılır."

  field :todoAdd do
    type TodoType
    description "Yapılacak işler listesine yeni bir iş ekler."
    argument :text, !types.String, 'Yapılacak işin metni.'
    resolve ->(obj, args, ctx) do
      todo = Todo.new(random_id, args[:text], false)
      todos << todo
      return todo
    end
  end

  field :todoComplete do
    type types[TodoType]
    description "Yapılacak işler listesindeki bir işi tamamlar."
    argument :id, !types.ID
    argument :status, !types.Boolean, 'İşin yeni durumu'
    resolve ->(obj, args, ctx) do
      todos.each do |todo|
        todo.isCompleted = args[:status] if todo[:id] == args[:id]
      end
      return todos
    end

    # will be deprecated
  end

  field :todoRemove do
    type types[TodoType]
    description "Yapılacak işler listesinden işi kaldırır."
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
