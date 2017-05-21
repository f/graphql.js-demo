var todos = document.getElementById("todos")
getTodos().then(function (data) {
  data.allTodos.forEach(function (todo) {
    if (todo.isCompleted) {
      todos.innerHTML += "<li class='completed' id='" + todo.id + "'>" + todo.text + "</li>"
    } else {
      todos.innerHTML += "<li id='" + todo.id + "'>" + todo.text + "</li>"
    }
  })
})

todos.addEventListener('click', function (e) {
  if (e.target.className == 'completed') {
    removeTodo(e.target.getAttribute('id')).then(function () {
      todos.removeChild(e.target)
    })
  }
  if (e.target.tagName == 'LI') {
    setTodo(e.target.getAttribute('id'), true).then(function () {
      e.target.className = "completed"
    })
  }
})

document.getElementById('addTodo').addEventListener('keydown', function (e) {
  if (e.keyCode != 13) return;
  addTodo(e.target.value).then(function (data) {
    todos.innerHTML += "<li id='" + data.todoAdd.id + "'>" + data.todoAdd.text + "</li>"
    e.target.value = '';
  })
})