# AI Agent Instructions

## After Making Code Changes

Always run the following commands before committing:

1. **Fix lint**: `bundle exec rubocop -a`
2. **Update rubocop todo**: `bundle exec rubocop --auto-gen-config`
3. **Run tests**: `bundle exec rspec`

## Changelog

Update [CHANGELOG.md](CHANGELOG.md) for any user-facing change. Add a line at the top under `### Changelog` in the format:

```
* YYYY/MM/DD: Description of change - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
```

## Tests

- Tests live in `spec/` and use RSpec with Fabrication for factories (`spec/fabricators/`).
- Write tests for all new features and bug fixes.
- Requires a local MongoDB instance (see `config/mongoid.yml`).

## Code Style

- Ruby style is enforced via RuboCop (`.rubocop.yml`). Persistent exceptions live in `.rubocop_todo.yml`.
- Do not add new entries to `.rubocop_todo.yml` for code you write — fix the offenses instead.

## Commits and PRs

- Squash commits before merging — one logical commit per PR.
