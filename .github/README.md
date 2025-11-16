# ShamelaGPT CI/CD Workflows

This directory contains the GitHub Actions workflows for continuous integration and deployment.

## Workflows

### 1. `ios-tests.yml`
- **Trigger**: Push/PR changes under `shamelagpt-ios/**`.
- **Steps**:
  - Checkout code.
  - Select Xcode and cache Swift packages.
  - Run Unit Tests.
  - Run UI Tests.
  - Upload `.xcresult` artifacts.
  - Upload unit coverage summary (`xccov` report text).
  - Store outputs under workspace-relative `artifacts/ios-tests/**`.

### 2. `android-tests.yml`
- **Trigger**: Push/PR changes under `shamelagpt-android/**`.
- **Steps**:
  - Checkout code.
  - Setup JDK 17.
  - Run Gradle Unit Tests.
  - Generate JaCoCo coverage (`jacocoTestReport`).
  - Run instrumented tests on phone emulator.
  - Run localized smoke on tablet emulator profile (`pixel_c`).
  - Upload connected test + raw instrumentation outputs.
  - Upload JaCoCo HTML/XML artifacts.

### 3. `tests.yml`
- **Trigger**: Push/PR on `main`.
- **Steps**:
  - Reuses `ios-tests.yml` and `android-tests.yml`.
  - Publishes final pass/fail summary status.

### 4. `openapi-contract-drift.yml`
- **Trigger**:
  - Scheduled weekly (Monday 06:00 UTC)
  - Manual dispatch
  - Push/PR changes touching OpenAPI contract file or contract-mapping tests
- **Steps**:
  - Run Android `OpenApiContractMappingTest`.
  - Run iOS `OpenAPIContractMappingTests`.
  - Upload Android test report and iOS `.xcresult` artifact.
  - Store iOS drift-check output under `artifacts/ios-openapi-contract/**`.

## Secrets
Current test workflows are configured for simulator/emulator test runs and do not require release-signing secrets.

## Quality Gates
We enforce several quality gates before a PR can be merged:
1. **Successful Build**: Both iOS and Android apps must compile.
2. **Test Pass**: All unit and UI tests must pass.
3. **Artifacts Published**: Coverage and result bundles are uploaded for triage.

## Local Emulation
To test workflows locally, you can use [act](https://github.com/nektos/act) or simply run the corresponding platform test commands in your terminal.
