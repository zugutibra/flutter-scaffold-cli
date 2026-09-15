## 0.1.0

- Initial release.
- `clean_flutter create <name>`: scaffolds a new Flutter project with a
  Clean Architecture + BLoC folder structure and a fully working example
  "Todo" feature (domain/data/presentation, wired through `get_it`).
  Supports `--org`, `--state bloc` (default and only option today), and
  `--db hive|isar|none` (default `hive`).
- `clean_flutter generate feature <name>`: adds an empty-but-structured
  feature slice (domain/data/presentation folders + repository/BLoC
  skeletons) to an existing project, with a manual DI-registration
  checklist printed afterwards.
