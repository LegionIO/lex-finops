# Changelog

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
