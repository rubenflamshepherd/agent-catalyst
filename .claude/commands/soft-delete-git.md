# Soft Delete Git Branch Workflow

## Steps:

1. **Get current branch name**
   ```bash
   git status
   ```

2. **Check out main branch**
   ```bash
   git checkout main
   ```

3. **Pull latest changes**
   ```bash
   git pull
   ```

4. **Soft delete the previous branch**
   ```bash
   git branch -d <branch-name>
   ```

## Notes:
- Uses lowercase `-d` for soft delete (safe delete that prevents deletion of unmerged branches)
- If soft delete fails, escalate to user rather than using uppercase `-D` (hard delete)
- The workflow ensures main is up to date before attempting the delete