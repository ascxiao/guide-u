# GitHub Flow & Branch Naming Conventions

## Overview

This repository uses a structured GitHub flow and branch protection rules to ensure code quality and consistency. The following conventions and rules are enforced based on the rulesets in `docs/rulesets/`.

---

## GitHub Flow

1. **Main Branch (`main`)**
   - Protected by status checks and pull request reviews.
   - Direct pushes are not allowed.
   - All changes must be merged via pull requests.
   - At least one approving review is required.
   - Status checks (e.g., `check-source-branch`) must pass before merging.
   - Non-fast-forward merges and branch deletions are prevented.

2. **Development Branch (`dev`)**
   - Requires pull requests for all changes.
   - At least one approving review is required.
   - Stale reviews are dismissed on new pushes.
   - Last push approval and review thread resolution are enforced.
   - Non-fast-forward merges and branch deletions are prevented.

---

## Branch Naming Conventions

- Branches (except `main`, `dev`, `frontend`, `backend`, `web`) must follow this pattern:

  ```
  <type>/<area>/<description>
  ```

  - **type**: `feat`, `fix`, `chore`, `docs`, `refactor`
  - **area**: `frontend`, `backend`, `web`, `core`
  - **description**: lowercase, numbers, hyphens (e.g., `add-login-form`)

  **Example:**
  - `feat/frontend/add-login-form`
  - `fix/backend/api-error`

---

## Creating a Feature Branch

1. Start from `dev` or the relevant area branch.
2. Name your branch according to the convention.
3. Push your branch and open a pull request.
4. Ensure all status checks and reviews are completed before merging.

---

## Summary

- All code changes go through pull requests.
- Branches must follow naming conventions.
- Reviews and status checks are required for merges.
- Direct pushes to protected branches are not allowed.

For details, see the rulesets in `docs/rulesets/`.
