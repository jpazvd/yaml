# QA Fixtures

YAML test fixtures for the QA test suite.

## Auto-extraction

The YAML files are **not tracked in git** to keep the repository small.
They are stored in `fixtures.zip` and automatically extracted when you
run the QA suite for the first time:

```stata
cd c:/GitHub/myados/yaml-dev
do qa/run_tests.do
```

## Manual extraction

If automatic extraction fails, extract manually:

**Windows (PowerShell):**
```powershell
Expand-Archive -Path qa/fixtures/fixtures.zip -DestinationPath qa/fixtures -Force
```

**Unix/macOS:**
```bash
unzip -o qa/fixtures/fixtures.zip -d qa/fixtures
```

## Updating fixtures

After modifying or adding YAML fixtures, update the zip:

```powershell
cd qa/fixtures
Compress-Archive -Path *.yaml -DestinationPath fixtures.zip -Force
```

Then commit `fixtures.zip` (the YAML files are gitignored).
