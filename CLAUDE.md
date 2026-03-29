# lex-finops

**Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## What Is This Gem?

Budget enforcement, cost attribution, and FinOps reporting for LegionIO. Enforces monthly per-worker and per-tenant spending limits, records actual spend, and fires budget alert events via `Legion::Events`.

**Gem**: `lex-finops`
**Version**: 0.1.2
**Namespace**: `Legion::Extensions::Finops`

## File Structure

```
lib/legion/extensions/finops/
  version.rb
  helpers/
    budget_store.rb      # BudgetStore — check_budget, record_spend, set_budget, status
    cost_calculator.rb   # Cost calculation helpers
  runners/
    budget.rb            # check_budget, record_spend, set_budget, budget_status
    cost_attribution.rb  # Cost attribution and reporting runners
```

## Key Design Decisions

- `check_budget` checks worker AND tenant budgets in one call; returns the first hard-stop result or `{ allowed: true }`
- `record_spend` records for worker + tenant + team simultaneously (skips nil entity IDs)
- Budget alerts fire via `Legion::Events.emit('finops.budget_alert', alert)` when defined; silently skipped otherwise
- Period key format: `YYYY-MM` (current UTC month) — budgets reset monthly
- `hard_stop: true` means the agent is blocked from proceeding; `false` means alerts fire but the task continues

## Integration Points

- **legion-llm**: check budget before LLM calls; record spend from token usage response
- **lex-metering**: lex-finops handles USD budgets; lex-metering handles raw token/invocation counts
- **Legion::Events**: budget alert events for downstream notification

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```
