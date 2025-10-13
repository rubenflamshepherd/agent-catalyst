## Git Workflow

### Branch Creation and Naming Convention

When working on fixes, create a new branch with this naming format:
```
[2-4 descriptive words]-[MMDD]
```

- **2-4 words**: Lowercase, separated by dashes, describing the issue being fixed
- **Date**: Today's date in MMDD format (month-month-day-day)

**Examples:**
- `fix-sqlfluff-errors-1214` (December 14th)
- `update-dbt-models-0103` (January 3rd)
- `align-as-keywords-0925` (September 25th)

### Complete Workflow

1. **Check to see if we are in a new branch**

   ```bash
   git status
   ```

   If we are are not you can **create and checkout new branch:**
   ```bash
   git checkout -b <new-branch-name-MMDD>
   ```

1. **Make your changes and commit:**

   Add any files that are untracked.

   ```bash
   # Add all changed files
   git add .

   # Commit with descriptive message
   git commit -m "<Overview of the change>

   - <item 1 in the more specific bulleted list of changes>
   - ...
   ```

2. **Push branch and create PR:**
   ```bash
   # Push to remote
   git push -u origin <new-branch-name-MMDD>

   # Create pull request
   gh pr create --title "<Descriptive PR Title>" --body "$(cat <<'EOF'
   ## Summary
   • Bulleted list of summary

   ## TODO list
   - [x] TODO List itms
   - [x] ...

   EOF
   )"
   ```
