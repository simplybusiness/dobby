# Dobby

“Dobby is free.”

A Github action which provides chat-ops functionality. You can comment on Pull request to perform various operations.
Currently it supports bumping version for a gem.

## Bump version

### Installation
Dobby require a github app to be installed on your repository. If you have already created a github app you can follow instruction from step 3 otherwise follow these steps: 

1. [Create a minimal GitHub App](https://docs.github.com/en/developers/apps/creating-a-github-app), setting the following fields:
   - Set GitHub App name. 
   - Set Homepage URL to anything you like, such as your GitHub profile page.
   - Uncheck Active under Webhook. You do not need to enter a Webhook URL.
   - Under Repository permissions: Contents select Access: Read & write.
   - Under Repository permissions: Pull requests select Access: Read & write. 

2. Create a Private key from the App settings page and store it securely.

3. Install the App on your repository.

4. Set secrets on your repository containing the GitHub App ID, and the private key you created in step 2. e.g. DOBBY_APP_ID, DOBBY_PRIVATE_KEY

5. Add a file to your github workflow `.github/workflows/dobby-action.yml` with following content:

```yaml

name: "dobby action"
on:
  issue_comment:
    types: [created]
jobs:
  pr_commented:
    runs-on: ubuntu-20.04
    if: startsWith(github.event.comment.body, '/dobby')
    
    steps:
      - name: bump version
        uses: simplybusiness/dobby@v1.1.0
        env:
          DOBBY_APP_ID: ${{ secrets.DOBBY_APP_ID }}
          DOBBY_PRIVATE_KEY: ${{ secrets.DOBBY_PRIVATE_KEY }}
          # Change to the file path where you keep the Gem's version.
          # It is usually `lib/<gem name>/version.rb` or in the gemspec file.
          VERSION_FILE_PATH: <VERSION FILE PATH>
```

**NOTE:** Workflow will only work once it merged to default (usually master) branch. It is because event `issue_comment` only work on default branch. See [discussion](https://github.community/t/on-issue-comment-events-are-not-triggering-workflows/16784/4) for more detail.


### How to use

1. Add the following comment in the pull request to bump the version.

```
/dobby version <semver level>
```
where semver level can be minor/major/patch.

2. You can see bot will add a comment on Pull request.
   
   ![Version update comment](docs/images/version-update.png)

