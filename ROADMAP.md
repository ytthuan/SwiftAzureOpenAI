# SwiftAzureOpenAI Roadmap

> **🎉 Status Update**: Most of the original roadmap has been **completed** during internal development. This document now serves as a historical reference and outlines remaining future enhancements.

## Completed Implementation Status

SwiftAzureOpenAI has successfully implemented all core planned features:

- ✅ **Responses API**: Complete implementation with streaming and non-streaming support
- ✅ **File API**: Full Azure OpenAI File API integration
- ✅ **Embeddings API**: Vector embeddings with batch processing utilities
- ✅ **Code Generation**: Automated OpenAPI model generation
- ✅ **Core Infrastructure**: HTTP client, retries, timeouts, logging
- ✅ **Ergonomics**: Python-style client API, caching, metrics, observability
- ✅ **Multi-platform**: iOS, macOS, watchOS, tvOS support with Swift 6.0+

Focused Scope:
- Platform: Azure OpenAI (primary), compatible with OpenAI core where trivial.
- Features: Responses API, File API, Embeddings (completed).
- Modalities: Text + Vision (images, PDFs/doc inputs). No audio, no realtime.

## Guiding Principles
1. Minimal Surface Area – Only implement endpoints required by common Swift app scenarios.
2. Strong Typing + Ergonomics – High-level Swift-friendly API on top of lower-level DTOs.
3. Reliability First – Retries, timeouts, error taxonomy before breadth.
4. Selective Code Generation – Generate only the low-level models & parameter structs.
5. Forward Compatible – Unknown JSON fields must not break decoding.

## Phase Overview

| Phase | Theme | Status | Description |
|-------|-------|--------|-------------|
| 0 | Core Hardening | ✅ **Completed** | Retries, timeouts, logging, HTTP abstraction, error taxonomy |
| 1 | Embeddings (Manual) | ✅ **Completed** | Add embeddings endpoint & examples |
| 2 | OpenAPI Generation (Selective) | ✅ **Completed** | Prune spec (Responses, Files, Embeddings) → generate DTOs |
| 3 | Hybrid Adoption | ✅ **Completed** | Optional migration of some manual models to generated adapters |
| 4 | Ergonomics & Observability | ✅ **Completed** | Similarity helpers, caching, metrics hooks |
| 5 | Conditional Expansion | 🔄 **Future** | Moderations or other endpoints if community demand arises |

## Phase 0 – Core Hardening ✅ **COMPLETED**
Implemented features:
- ✅ Retry & backoff (default 2 attempts; 429 & >=500)
- ✅ Timeout configuration (`global` + per request)
- ✅ `HTTPClientProtocol` with default `URLSessionHTTPClient`
- ✅ Central `AzureRequestBuilder` (endpoint, api-version, headers)
- ✅ Logging levels + pluggable logger
- ✅ Expanded error taxonomy

## Phase 1 – Embeddings ✅ **COMPLETED**
Implemented deliverables:
- ✅ `client.embeddings.create(...)`
- ✅ Request/Response types: `SAOAIEmbeddingsRequest`, `SAOAIEmbeddingsResponse`, `SAOAIEmbedding`
- ✅ Cosine similarity utility + example code
- ✅ README section + sample snippet
- ✅ Unit & fixture tests

## Phase 2 – Selective OpenAPI Generation ✅ **COMPLETED**
Implemented deliverables:
- ✅ Script: `Scripts/prune-openapi-spec.py`
- ✅ Pruned spec committed (`Specs/pruned-openapi.json`)
- ✅ Generated models in `Sources/SwiftAzureOpenAI/Generated/`
- ✅ Documentation: Code generation system fully documented

Implementation details:
- ✅ Only kept `/responses`, `/files`, `/embeddings`
- ✅ Removed extraneous schemas & security definitions
- ✅ Avoided overwriting hand-written high-level API

## Phase 3 – Hybrid Model Adoption ✅ **COMPLETED**
Implemented features:
- ✅ Created adapter in `Adapters/GeneratedAdapters.swift`
- ✅ Preserved existing manual enums for expressiveness
- ✅ Added unknown field retention strategy

## Phase 4 – Ergonomics & Observability ✅ **COMPLETED**
Implemented enhancements:
- ✅ Embedding batch helper with concurrency throttle (`EmbeddingBatchHelper`)
- ✅ In-memory embedding cache protocol (`ResponseCacheService`)
- ✅ Metrics delegate (request durations, status codes)
- ✅ Logging correlation IDs (requestId passthrough)

## Phase 5 – Conditional Expansion (Community Driven)
Potential (opened via Discussions/Polls):
- Moderations endpoint.
- Client-side vector search helpers.
- Document chunking utilities.

## Automation & Maintenance
- Nightly CI: regenerate → compare → open PR on changes.
- Versioning: Semantic Versioning (API additive = minor; breaking = major).
- Changelog: `CHANGELOG.md` required for each feature PR.

## Success Metrics
| Metric | Target |
|--------|--------|
| Embeddings feature release cycle | < 2 weeks |
| Spec update PR turnaround | < 48h |
| Decoding failures due to new fields | 0 |
| Reported reliability issues post Phase 0 | Downward trend |

## Open Questions
- Should Moderations be included earlier to support safety-by-default?
- Adopt Azure AD token flow (MSAL) or remain API key only in first half?

## How to Contribute
1. Open an Issue describing feature / fix.
2. For model shape changes, run generation script before committing.
3. Add tests + update `CHANGELOG.md`.

---
This roadmap is intentionally focused; realtime, audio, fine-tuning and assistants orchestration are out-of-scope unless strong user demand emerges.
