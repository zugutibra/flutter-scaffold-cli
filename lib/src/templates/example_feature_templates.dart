/// Templates for the bundled example "Todo" feature (see plan section 4).
/// Every generated project ships this feature fully wired so `flutter run`
/// shows a working add/view todo list with zero manual edits.
///
/// Database choice: the plan's MVP defaults to Isar, but Isar requires a
/// `build_runner` codegen pass before the project can build, which breaks
/// the "runs immediately" requirement. We default to **Hive** with a
/// hand-written `TypeAdapter` (no codegen needed) and still support
/// `--db isar` for people who want it — `create_command.dart` prints an
/// extra `dart run build_runner build` step in that case. `--db none` uses
/// a plain in-memory list, no persistence dependency at all.
enum DbChoice { hive, isar, none }

DbChoice dbChoiceFromFlag(String? flag) {
  switch (flag) {
    case 'isar':
      return DbChoice.isar;
    case 'none':
      return DbChoice.none;
    case 'hive':
    default:
      return DbChoice.hive;
  }
}

// ---------------------------------------------------------------------------
// Domain layer (identical regardless of --db)
// ---------------------------------------------------------------------------

String todoEntityTemplate(String packageName) => '''
import 'package:equatable/equatable.dart';

class Todo extends Equatable {
  const Todo({required this.id, required this.title, this.isDone = false});

  final int id;
  final String title;
  final bool isDone;

  Todo copyWith({int? id, String? title, bool? isDone}) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  List<Object?> get props => [id, title, isDone];
}
''';

String todoRepositoryTemplate(String packageName) =>
    '''
import 'package:fpdart/fpdart.dart';

import 'package:$packageName/core/errors/failures.dart';
import 'package:$packageName/features/example/domain/entities/todo.dart';

abstract class TodoRepository {
  Future<Either<Failure, List<Todo>>> getTodos();
  Future<Either<Failure, Todo>> addTodo(String title);
}
''';

String getTodosUsecaseTemplate(String packageName) =>
    '''
import 'package:fpdart/fpdart.dart';

import 'package:$packageName/core/errors/failures.dart';
import 'package:$packageName/core/usecases/usecase.dart';
import 'package:$packageName/features/example/domain/entities/todo.dart';
import 'package:$packageName/features/example/domain/repositories/todo_repository.dart';

class GetTodos implements UseCase<List<Todo>, NoParams> {
  GetTodos(this.repository);

  final TodoRepository repository;

  @override
  Future<Either<Failure, List<Todo>>> call(NoParams params) {
    return repository.getTodos();
  }
}
''';

String addTodoUsecaseTemplate(String packageName) =>
    '''
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:$packageName/core/errors/failures.dart';
import 'package:$packageName/core/usecases/usecase.dart';
import 'package:$packageName/features/example/domain/entities/todo.dart';
import 'package:$packageName/features/example/domain/repositories/todo_repository.dart';

class AddTodo implements UseCase<Todo, AddTodoParams> {
  AddTodo(this.repository);

  final TodoRepository repository;

  @override
  Future<Either<Failure, Todo>> call(AddTodoParams params) {
    return repository.addTodo(params.title);
  }
}

class AddTodoParams extends Equatable {
  const AddTodoParams(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}
''';

// ---------------------------------------------------------------------------
// Data layer — model varies per --db choice
// ---------------------------------------------------------------------------

String todoModelTemplate(String packageName, DbChoice db) {
  switch (db) {
    case DbChoice.isar:
      return '''
import 'package:isar/isar.dart';

import 'package:$packageName/features/example/domain/entities/todo.dart';

part 'todo_model.g.dart';

@collection
class TodoModel {
  TodoModel({this.id = Isar.autoIncrement, required this.title, this.isDone = false});

  Id id;
  late String title;
  late bool isDone;

  Todo toEntity() => Todo(id: id, title: title, isDone: isDone);

  factory TodoModel.fromEntity(Todo todo) =>
      TodoModel(id: todo.id == 0 ? Isar.autoIncrement : todo.id, title: todo.title, isDone: todo.isDone);
}
''';
    case DbChoice.hive:
      return '''
import 'package:hive/hive.dart';

import 'package:$packageName/features/example/domain/entities/todo.dart';

/// Hand-written adapter (no build_runner needed) — registered once in
/// injection_container.dart before the box is opened.
class TodoModel {
  TodoModel({required this.id, required this.title, this.isDone = false});

  final int id;
  final String title;
  final bool isDone;

  Todo toEntity() => Todo(id: id, title: title, isDone: isDone);

  factory TodoModel.fromEntity(Todo todo) =>
      TodoModel(id: todo.id, title: todo.title, isDone: todo.isDone);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'isDone': isDone};

  factory TodoModel.fromJson(Map<dynamic, dynamic> json) => TodoModel(
        id: json['id'] as int,
        title: json['title'] as String,
        isDone: json['isDone'] as bool,
      );
}

class TodoModelAdapter extends TypeAdapter<TodoModel> {
  @override
  final int typeId = 0;

  @override
  TodoModel read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return TodoModel.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, TodoModel obj) {
    writer.writeMap(obj.toJson());
  }
}
''';
    case DbChoice.none:
      return '''
import 'package:$packageName/features/example/domain/entities/todo.dart';

class TodoModel {
  TodoModel({required this.id, required this.title, this.isDone = false});

  final int id;
  final String title;
  final bool isDone;

  Todo toEntity() => Todo(id: id, title: title, isDone: isDone);

  factory TodoModel.fromEntity(Todo todo) =>
      TodoModel(id: todo.id, title: todo.title, isDone: todo.isDone);
}
''';
  }
}

String todoLocalDatasourceTemplate(String packageName, DbChoice db) {
  switch (db) {
    case DbChoice.isar:
      return '''
import 'package:isar/isar.dart';

import 'package:$packageName/core/errors/exceptions.dart';
import 'package:$packageName/features/example/data/models/todo_model.dart';

abstract class TodoLocalDataSource {
  Future<List<TodoModel>> getTodos();
  Future<TodoModel> addTodo(String title);
}

class TodoLocalDataSourceImpl implements TodoLocalDataSource {
  TodoLocalDataSourceImpl(this.isar);

  final Isar isar;

  @override
  Future<List<TodoModel>> getTodos() async {
    try {
      return await isar.todoModels.where().findAll();
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<TodoModel> addTodo(String title) async {
    try {
      final model = TodoModel(title: title);
      await isar.writeTxn(() async => isar.todoModels.put(model));
      return model;
    } catch (_) {
      throw const CacheException();
    }
  }
}
''';
    case DbChoice.hive:
      return '''
import 'package:hive/hive.dart';

import 'package:$packageName/core/errors/exceptions.dart';
import 'package:$packageName/features/example/data/models/todo_model.dart';

abstract class TodoLocalDataSource {
  Future<List<TodoModel>> getTodos();
  Future<TodoModel> addTodo(String title);
}

class TodoLocalDataSourceImpl implements TodoLocalDataSource {
  TodoLocalDataSourceImpl(this.box);

  final Box<TodoModel> box;

  @override
  Future<List<TodoModel>> getTodos() async {
    try {
      return box.values.toList();
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<TodoModel> addTodo(String title) async {
    try {
      final model = TodoModel(id: DateTime.now().millisecondsSinceEpoch, title: title);
      await box.put(model.id, model);
      return model;
    } catch (_) {
      throw const CacheException();
    }
  }
}
''';
    case DbChoice.none:
      return '''
import 'package:$packageName/core/errors/exceptions.dart';
import 'package:$packageName/features/example/data/models/todo_model.dart';

abstract class TodoLocalDataSource {
  Future<List<TodoModel>> getTodos();
  Future<TodoModel> addTodo(String title);
}

/// In-memory implementation (`--db none`) — data is lost on app restart.
class TodoLocalDataSourceImpl implements TodoLocalDataSource {
  final List<TodoModel> _todos = [];

  @override
  Future<List<TodoModel>> getTodos() async => List.unmodifiable(_todos);

  @override
  Future<TodoModel> addTodo(String title) async {
    try {
      final model = TodoModel(id: DateTime.now().millisecondsSinceEpoch, title: title);
      _todos.add(model);
      return model;
    } catch (_) {
      throw const CacheException();
    }
  }
}
''';
  }
}

String todoRepositoryImplTemplate(String packageName) =>
    '''
import 'package:fpdart/fpdart.dart';

import 'package:$packageName/core/errors/exceptions.dart';
import 'package:$packageName/core/errors/failures.dart';
import 'package:$packageName/features/example/data/datasources/todo_local_datasource.dart';
import 'package:$packageName/features/example/domain/entities/todo.dart';
import 'package:$packageName/features/example/domain/repositories/todo_repository.dart';

class TodoRepositoryImpl implements TodoRepository {
  TodoRepositoryImpl(this.localDataSource);

  final TodoLocalDataSource localDataSource;

  @override
  Future<Either<Failure, List<Todo>>> getTodos() async {
    try {
      final models = await localDataSource.getTodos();
      return Right(models.map((m) => m.toEntity()).toList());
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Todo>> addTodo(String title) async {
    try {
      final model = await localDataSource.addTodo(title);
      return Right(model.toEntity());
    } on CacheException {
      return const Left(CacheFailure());
    }
  }
}
''';

// ---------------------------------------------------------------------------
// Presentation layer (BLoC)
// ---------------------------------------------------------------------------

String todoEventTemplate(String packageName) => '''
import 'package:equatable/equatable.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodos extends TodoEvent {
  const LoadTodos();
}

class CreateTodo extends TodoEvent {
  const CreateTodo(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}
''';

String todoStateTemplate(String packageName) =>
    '''
import 'package:equatable/equatable.dart';

import 'package:$packageName/features/example/domain/entities/todo.dart';

abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object?> get props => [];
}

class TodoInitial extends TodoState {
  const TodoInitial();
}

class TodoLoading extends TodoState {
  const TodoLoading();
}

class TodoLoaded extends TodoState {
  const TodoLoaded(this.todos);

  final List<Todo> todos;

  @override
  List<Object?> get props => [todos];
}

class TodoError extends TodoState {
  const TodoError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
''';

String todoBlocTemplate(String packageName) =>
    '''
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:$packageName/core/usecases/usecase.dart';
import 'package:$packageName/features/example/domain/usecases/add_todo.dart';
import 'package:$packageName/features/example/domain/usecases/get_todos.dart';
import 'package:$packageName/features/example/presentation/bloc/todo_event.dart';
import 'package:$packageName/features/example/presentation/bloc/todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc({required this.getTodos, required this.addTodo}) : super(const TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<CreateTodo>(_onCreateTodo);
  }

  final GetTodos getTodos;
  final AddTodo addTodo;

  Future<void> _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    emit(const TodoLoading());
    final result = await getTodos(const NoParams());
    result.fold(
      (failure) => emit(TodoError(failure.message)),
      (todos) => emit(TodoLoaded(todos)),
    );
  }

  Future<void> _onCreateTodo(CreateTodo event, Emitter<TodoState> emit) async {
    final result = await addTodo(AddTodoParams(event.title));
    await result.fold(
      (failure) async => emit(TodoError(failure.message)),
      (_) async => add(const LoadTodos()),
    );
  }
}
''';

String todoPageTemplate(String packageName) =>
    '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:$packageName/features/example/presentation/bloc/todo_bloc.dart';
import 'package:$packageName/features/example/presentation/bloc/todo_event.dart';
import 'package:$packageName/features/example/presentation/bloc/todo_state.dart';

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          if (state is TodoLoading || state is TodoInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TodoError) {
            return Center(child: Text(state.message));
          }
          if (state is TodoLoaded) {
            if (state.todos.isEmpty) {
              return const Center(child: Text('No todos yet — add one below.'));
            }
            return ListView.builder(
              itemCount: state.todos.length,
              itemBuilder: (context, index) {
                final todo = state.todos[index];
                return ListTile(title: Text(todo.title));
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddTodoDialog(BuildContext context) async {
    final controller = TextEditingController();
    final bloc = context.read<TodoBloc>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New todo'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) bloc.add(CreateTodo(title));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
''';
