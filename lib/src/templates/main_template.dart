import 'example_feature_templates.dart';

String mainDartTemplate(String packageName, DbChoice db) {
  final preRunAppInit = switch (db) {
    DbChoice.hive =>
      '''
  await Hive.initFlutter();
  Hive.registerAdapter(TodoModelAdapter());
''',
    DbChoice.isar =>
      '''
  final dir = await getApplicationDocumentsDirectory();
  await Isar.open([TodoModelSchema], directory: dir.path);
''',
    DbChoice.none => '',
  };

  final imports = switch (db) {
    DbChoice.hive =>
      "import 'package:hive_flutter/hive_flutter.dart';\n"
          "import 'package:$packageName/features/example/data/models/todo_model.dart';\n",
    DbChoice.isar =>
      "import 'package:isar/isar.dart';\n"
          "import 'package:path_provider/path_provider.dart';\n"
          "import 'package:$packageName/features/example/data/models/todo_model.dart';\n",
    DbChoice.none => '',
  };

  return '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
$imports
import 'package:$packageName/core/di/injection_container.dart';
import 'package:$packageName/features/example/presentation/bloc/todo_bloc.dart';
import 'package:$packageName/features/example/presentation/bloc/todo_event.dart';
import 'package:$packageName/features/example/presentation/pages/todo_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
$preRunAppInit
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$packageName',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: BlocProvider(
        create: (_) => sl<TodoBloc>()..add(const LoadTodos()),
        child: const TodoPage(),
      ),
    );
  }
}
''';
}

/// Import lines the example feature's DI registration needs at the top of
/// `injection_container.dart`.
String exampleFeatureDiImports(String packageName, DbChoice db) {
  final dbImport = switch (db) {
    DbChoice.hive => "import 'package:hive/hive.dart';\n",
    DbChoice.isar => "import 'package:isar/isar.dart';\n",
    DbChoice.none => '',
  };
  // Only `--db hive` references TodoModel directly (as `Box<TodoModel>`) in
  // the registration block below; importing it unconditionally would leave
  // an unused-import warning for `--db isar`/`none`.
  final modelImport = db == DbChoice.hive
      ? "import 'package:$packageName/features/example/data/models/todo_model.dart';\n"
      : '';
  return '''
${dbImport}import 'package:$packageName/features/example/data/datasources/todo_local_datasource.dart';
${modelImport}import 'package:$packageName/features/example/data/repositories/todo_repository_impl.dart';
import 'package:$packageName/features/example/domain/repositories/todo_repository.dart';
import 'package:$packageName/features/example/domain/usecases/add_todo.dart';
import 'package:$packageName/features/example/domain/usecases/get_todos.dart';
import 'package:$packageName/features/example/presentation/bloc/todo_bloc.dart';
''';
}

/// The DI registration block for the example feature, injected into
/// `injection_container.dart`'s `initDependencies()` body.
String exampleFeatureDiRegistration(String packageName, DbChoice db) {
  final dataSourceRegistration = switch (db) {
    DbChoice.hive =>
      '''
  final todoBox = await Hive.openBox<TodoModel>('todos');
  sl.registerLazySingleton<TodoLocalDataSource>(() => TodoLocalDataSourceImpl(todoBox));''',
    DbChoice.isar =>
      '''
  sl.registerLazySingleton<TodoLocalDataSource>(() => TodoLocalDataSourceImpl(Isar.getInstance()!));''',
    DbChoice.none =>
      '''
  sl.registerLazySingleton<TodoLocalDataSource>(TodoLocalDataSourceImpl.new);''',
  };

  return '''
  // ---- Example (Todo) feature ----
$dataSourceRegistration
  sl.registerLazySingleton<TodoRepository>(() => TodoRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetTodos(sl()));
  sl.registerLazySingleton(() => AddTodo(sl()));
  sl.registerFactory(() => TodoBloc(getTodos: sl(), addTodo: sl()));''';
}
