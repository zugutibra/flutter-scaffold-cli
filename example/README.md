# example

`flutter_scaffold_cli` is a command-line tool, so its "example" is a CLI
session rather than a Dart API.

## Scaffold a new project

```sh
dart pub global activate flutter_scaffold_cli
clean_flutter create my_app --org com.example
cd my_app
flutter pub get
flutter run
```

This generates a Flutter project with:

- `lib/core/` — DI container, base `Failure`/`Exception` types, base `UseCase`
- `lib/features/example/` — a complete Todo feature (domain/data/presentation)
  wired through `get_it`, so the app runs immediately with a working
  add/view todo list.

## Add a feature to that project

```sh
clean_flutter generate feature payments
```

Generates `lib/features/payments/{domain,data,presentation}/` with a
repository interface/impl stub and a BLoC skeleton, and prints the manual
`injection_container.dart` registrations needed to wire it up.

See the [top-level README](../README.md) for the full flag reference.
