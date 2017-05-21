var graph = graphql("/graphql", {
  alwaysAutodeclare: true,
  fragments: {
    todo: `on Todo {
      id
      text
      isCompleted
    }`
  }
})

function getTodos() {
  return graph.query.run(`
    allTodos {
      ...todo
    }
  `)
}

function addTodo(text) {
  return graph.mutate(`
    todoAdd(text: $text) {
      ...todo
    }
  `)({
    text: text
  })
}

function setTodo(id, isCompleted) {
  return graph.mutate(`
    todoComplete(id: $id, status: $isCompleted) {
      ...todo
    }
  `)({
    "id!ID": id,
    isCompleted: isCompleted
  })
}

function removeTodo(id) {
  return graph.mutate(`
    todoRemove(id: $id) {
      ...todo
    }
  `)({
    "id!ID": id
  })
}
