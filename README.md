# Dobby

“Dobby is free.”

A Github action which provides chat-ops functionality. You can comment on a pull request to perform various operations.
Currently it supports bumping version files in Ruby, Python and Javascript. The version file (see below) must specify the version
as a key-value pair separated by either ":" or "=", e.g. `VERSION: '1.2.3'` or `version = 1.2.3` 

## Bump version

### Installation
Dobby requires a Github App to be installed either on an individual repository or organization wide. If you have already created a Github App you can follow instruction from step 3. Otherwise follow these steps: 

1. [Create a minimal GitHub App](https://docs.github.com/en/developers/apps/creating-a-github-app), setting the following fields:
   - Set GitHub App name. 
   - Set Homepage URL to your github repository.
   - Uncheck Active under Webhook. You do not need to enter a Webhook URL.
   - Under Permissions & Events > Repository permissions > Contents select Access: Read & write.
   - Under Permissions & Events > Repository permissions > Pull requests select Access: Read & write. 

2. Create a Private key from the App settings page and store it securely.

3. Install the App either on your repository or organization wide.

4. Set secrets on your repository or organization containing the GitHub App ID, and the private key you created in step 2 as DOBBY_APP_ID, DOBBY_PRIVATE_KEY

5. Add a file to your github workflow `.github/workflows/dobby-action.yml` with following content:

```yaml

name: "Dobby action"
on:
  issue_comment:
    types: [created]
jobs:
  pr_commented:
    runs-on: ubuntu-20.04
    if: startsWith(github.event.comment.body, '/dobby')
    env:
      BUNDLE_WITHOUT: "development:test"
    steps:
      - name: Checkout action
        uses: actions/checkout@v2
        with:
          repository: 'simplybusiness/dobby'
          ref: 'v3'
      - name: Set up ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Bump version
        uses: simplybusiness/dobby@v3
        env:
          DOBBY_APP_ID: ${{ secrets.DOBBY_APP_ID }}
          DOBBY_PRIVATE_KEY: ${{ secrets.DOBBY_PRIVATE_KEY }}
          # Change to the file path where you keep the Gem's version.
          # It is usually `lib/<gem name>/version.rb` or in the gemspec file.
          VERSION_FILE_PATH: <VERSION FILE PATH>
          # OPTIONAL: Comma separated values for any other files that lock
          # their version to the same version in VERSION_FILE_PATH
          OTHER_VERSION_FILE_PATHS: 'package.json,package-lock.json,yarn.lock'
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
