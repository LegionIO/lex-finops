# Changelog

## [0.1.3] - 2026-03-30

### Changed
- update to rubocop-legion 0.1.7, resolve all offenses

## [0.1.2] - 2026-03-23

### Changed
- Implement real `cost_summary` runner: aggregates metering_records by worker_id/provider/model_id with token sums when legion-data is connected
- Returns `{ error: 'data_unavailable' }` when metering tables are not present (replaces static note placeholder)
- Column allowlist (`SUMMARY_COLUMNS`) prevents SQL injection in group_by parameter

## [0.1.1] - 2026-03-22

### Changed
- Add legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport as runtime dependencies
- Update spec_helper with real sub-gem helper requires and Helpers::Lex stub

## [0.1.0] - 2026-03-17

### Added
- `Helpers::CostCalculator`: token-to-USD cost estimation with configurable pricing per provider/model
- `Helpers::BudgetStore`: in-memory per-entity budget tracking with threshold alerts (50/75/90/100%)
- `Runners::Budget`: check_budget, record_spend, set_budget, budget_status with multi-entity support
- `Runners::CostAttribution`: attribute_cost with full provenance (worker, tenant, team, task, extension)
- Hard stop option for budget enforcement
