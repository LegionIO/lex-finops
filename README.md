# lex-finops

Budget enforcement, cost attribution, and FinOps reporting for LegionIO. Tracks per-worker and per-tenant spending, enforces budget limits with optional hard stops, and fires budget alert events when thresholds are crossed.

## Overview

`lex-finops` provides financial guardrails for LLM-powered agents. Workers and tenants have monthly spending budgets. Before starting a task, an agent checks whether the estimated cost fits within budget. After completing a task, it records the actual spend. Alerts fire at configurable thresholds.

## Installation

```ruby
gem 'lex-finops'
```

## Usage

```ruby
require 'legion/extensions/finops'

client = Legion::Extensions::Finops::Client.new

# Set a budget
client.set_budget(
  entity_type: :worker,
  entity_id: 'agent-42',
  limit_usd: 50.0,
  hard_stop: true
)
# => { set: true, entity_type: :worker, entity_id: 'agent-42', limit_usd: 50.0 }

# Check before running a task
client.check_budget(
  worker_id: 'agent-42',
  tenant_id: 'acme-corp',
  estimated_cost: 0.05
)
# => { allowed: true }
# When over budget: { allowed: false, reason: :hard_stop, entity_id: 'agent-42', ... }

# Record actual spend after a task
client.record_spend(
  worker_id: 'agent-42',
  cost_usd: 0.04,
  tenant_id: 'acme-corp',
  team: 'platform'
)
# => { recorded: true, alerts_fired: 0 }

# Check current status
client.budget_status(entity_type: :worker, entity_id: 'agent-42')
```

## Budget Scopes

| Scope | Description |
|-------|-------------|
| `:worker` | Per-agent worker budget |
| `:tenant` | Per-tenant aggregate budget |
| `:team` | Per-team aggregate budget |

All scopes are checked/recorded simultaneously. A single `check_budget` call checks both the worker and tenant budgets — the first exceeded hard-stop blocks.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
