# gitlab-scripts

Please install “jq” for JSON parsing.

## find GitLab-Runner

```bash
./find_runner.sh
```

or

```bash
./find_runner.sh fast
```

With "fast" argument: Stop at the first runner. This is useful if you only have one active runner.
