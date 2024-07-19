# gitlab-scripts


## find GitLab-Runner (Python >=3.11)

Edit the `.env` file for GitLab token and domain.

```bash
python ./find_runner.py
```

## find GitLab-Runner (BASH)

Please install “jq” for JSON parsing.

```bash
./find_runner.sh
```

or

```bash
./find_runner.sh fast
```

With "fast" argument: Stop at the first runner. This is useful if you only have one active runner.
