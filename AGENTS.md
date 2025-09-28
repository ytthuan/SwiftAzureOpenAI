# AGENTS.md

> **⚠️ Internal Development**: This document provides coding agent instructions for the internal development team working on the SwiftAzureOpenAI SDK. It contains development procedures and standards for our internal development process.

## Project Overview
SwiftAzureOpenAI is a Swift Package that provides Swift-native models, client utilities, and services for Azure OpenAI and OpenAI Responses API. It targets Apple platforms (iOS, macOS, watchOS, tvOS) and supports both non-streaming and streaming (SSE) responses with strong typing, metadata extraction, and optional response caching.

- Primary focus: Responses API (unified, stateful API combining chat, tools, assistants)
- Client style: Python-inspired `client.responses.create(...)` and `createStreaming(...)`
- Services: Optimized parsing/streaming; robust error handling; response metadata and rate limit extraction

## Repository Structure
```
Sources/SwiftAzureOpenAI/
├── Core/                  # Config, HTTP client, Responses client
├── Models/                # Codable request/response/common models
├── Services/              # Parsing, validation, streaming, caching, SSE
├── Extensions/            # Foundation helpers
examples/                  # Standalone sample Swift packages
Tests/SwiftAzureOpenAITests/# 80+ tests covering models, services, streaming, etc.
docs/                      # CI/CD, live API testing, release guide, best practices
```

Key entry points for agents:
- `Sources/SwiftAzureOpenAI/Core/ResponsesClient.swift`: high-level Responses API client
- `Sources/SwiftAzureOpenAI/Services/ResponseService*.swift`: response processing
- `Sources/SwiftAzureOpenAI/Services/Optimized*.swift`: performance-focused implementations
- `Sources/SwiftAzureOpenAI/Models/Requests` and `Models/Responses`: Codable types
- `Tests/SwiftAzureOpenAITests/*`: authoritative usage, edge cases, SSE, function calling

## Development Commands
- Build: `swift build`
- Run tests (all): `swift test`
- Run specific tests: `swift test --filter <TestCaseOrMethod>`
- Run examples:
  - `cd examples/ConsoleChatbot && swift run`
  - `cd examples/ResponsesConsoleChatbot && swift run`
- Release prep validation: `./scripts/prepare-release.sh`

## Environment Variables
Used by tests and examples; see `Tests/SwiftAzureOpenAITests/TestEnvironmentHelper.swift` and `docs/LIVE_API_TESTING.md`.

Azure OpenAI:
- `AZURE_OPENAI_ENDPOINT` (e.g., https://your-resource.openai.azure.com)
- `COPILOT_AGENT_AZURE_OPENAI_API_KEY` (preferred) or `AZURE_OPENAI_API_KEY`
- `AZURE_OPENAI_DEPLOYMENT` (deployment/model name, e.g., gpt-4o)
- `AZURE_OPENAI_API_VERSION` (default: `preview`)

OpenAI (optional for examples):
- `OPENAI_API_KEY`

## Code Style and Practices
- Swift 5.9+/6, async/await and structured concurrency
- Codable models with `CodingKeys` mirroring API fields
- Prefer value types; typed errors via `SAOAIError` and `ErrorResponse`
- Clear naming: SAOAI-prefixed public API types (e.g., `SAOAIClient`, `SAOAIRequest`)
- No external dependencies; SPM only
- Keep lines ≤120 chars; preserve existing formatting

Error handling (representative):
- Network/decoding errors mapped to `SAOAIError`
- HTTP status validation in response services
- API error payloads decoded into `ErrorResponse`

## Testing Guidance for Agents
- Default: `swift test`
- Live API tests require env vars; otherwise they skip gracefully
- To run live tests (after exporting env vars):
  - `swift test --filter LiveAPITests`
  - Individual filters are documented in `docs/LIVE_API_TESTING.md`
- When adding features, include unit tests covering public APIs, streaming paths, and error cases. Use dependency injection for services.

## Agent Interaction Guidelines
- Follow Responses API-first design; add Codable models under `Models/`
- Extend clients/services without breaking public API semver
- For streaming, use `AsyncThrowingStream` and SSE parser services provided
- Extract metadata (request id, rate limit) from headers in services
- Do not hardcode secrets; use env vars; redact in logs
- Preserve existing APIs and examples; avoid refactors that break tests without necessity

## Common Workflows
- Implement new response field:
  1) Update `Models/Responses/*` structs with `CodingKeys`
  2) Adjust parsing/validation services if needed
  3) Add tests in `Tests/SwiftAzureOpenAITests/*`

- Add request option:
  1) Update `Models/Requests/*`
  2) Thread through `ResponsesClient` and services
  3) Add unit tests and example snippet

## CI/CD and Releases
- CI: GitHub Actions run build and tests on macOS/Linux
- Release flow with approval and tagging; see `docs/CI-CD.md`
- Pre-release validation: `./scripts/prepare-release.sh`

## Useful Links
- README: project overview and usage
- Live API testing: `docs/LIVE_API_TESTING.md`
- CI/CD details: `docs/CI-CD.md`
- Examples: `examples/`

## Pull Request Guidelines
- Target `main` via feature branches
- Keep changes minimal and scoped; include tests and docs updates
- Ensure `swift build` and `swift test` pass locally
- Do not add external dependencies
- Use semantic, conventional commit messages where possible
