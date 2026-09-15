# clean_flutter_cli

[![CI](https://github.com/zugutibra/clean-flutter-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/zugutibra/clean-flutter-cli/actions/workflows/ci.yml)

A Dart CLI that scaffolds new Flutter projects — and new feature slices in
existing ones — following **Clean Architecture + BLoC**, matching the
layered `domain` / `data` / `presentation` structure used across production
apps.

```
lib/
├── core/
│   ├── di/injection_container.dart   # get_it setup
│   ├── errors/{failures,exceptions}.dart
│   ├── usecases/usecase.dart         # base UseCase<Type, Params>
│   └── utils/input_converter.dart
├── features/
│   └── example/                      # a fully working Todo feature
│       ├── domain/{entities,repositories,usecases}/
│       ├── data/{models,datasources,repositories}/
│       └── presentation/{bloc,pages,widgets}/
└── main.dart
```

Every generated project comes with a complete, working example feature — a
Todo list — wired end-to-end through `get_it`, so `flutter run` shows
something real instead of the default counter app.

## Install

```sh
dart pub global activate clean_flutter_cli
```

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) on
your `PATH` (the `create` command shells out to `flutter create`).

## Usage

### Create a new project

```sh
clean_flutter create my_app [--org com.example] [--db hive|isar|none]
```

```
$ clean_flutter create my_app --org com.example
✓ Base Flutter project created

✔ Generated 17 files in my_app/

Next steps:
  cd my_app
  flutter pub get
  flutter run
```

| Flag      | Default | Description                                         |
| --------- | ------- | ---------------------------------------------------- |
| `--org`   | —       | Bundle identifier, passed through to `flutter create`. |
| `--state` | `bloc`  | State management approach (only `bloc` today).       |
| `--db`    | `hive`  | Persistence for the example Todo feature — see below. |

### Add a feature to an existing project

```sh
clean_flutter generate feature payments [--path lib/]
```

Scaffolds `lib/features/payments/{domain,data,presentation}/` with a
repository interface/impl stub and a BLoC skeleton, named after the
feature. It is **not** wired into DI automatically — the command prints
the exact `injection_container.dart` registrations and `BlocProvider`
wiring to add by hand, and detects the host project's `--db` choice so its
next-step notes match (e.g. it won't suggest Isar boilerplate for a
Hive-based project).

## Design choices worth knowing

- **Persistence defaults to Hive, not Isar.** Isar needs a `build_runner`
  codegen pass before the project even compiles, which breaks the "runs
  immediately" goal. `--db hive` uses a hand-written `TypeAdapter` (no
  codegen). `--db isar` is still supported — `create` prints the extra
  `dart run build_runner build --delete-conflicting-outputs` step it
  needs. `--db none` uses a plain in-memory list (no persistence
  dependency at all).
- **Either-based error handling uses [`fpdart`](https://pub.dev/packages/fpdart),
  not `dartz`.** Same `Either<Failure, T>` pattern, actively maintained,
  built for null safety.
- **Templates are raw Dart string functions** under `lib/src/templates/`
  (no external templating engine). Simple to read, simple to test with
  golden-file comparisons — see `test/fixtures/`.

## Development

```sh
dart pub get
dart analyze
dart test --exclude-tags e2e   # fast: unit + golden + generate-feature tests
dart test --tags e2e           # slow: shells out to `flutter create`, needs Flutter on PATH
```

Regenerate golden fixtures after intentionally changing a template's
output:

```sh
dart run tool/write_fixtures.dart
```

## Publishing

`.github/workflows/publish.yml` publishes to pub.dev on any `v*.*.*` tag
push, using [pub.dev's OIDC-based automated publishing](https://dart.dev/tools/pub/automated-publishing)
(no stored credentials). Before the first tagged release, connect this
repo on the package's pub.dev admin page ("Automated publishing").

## License

MIT — see [LICENSE](LICENSE).
