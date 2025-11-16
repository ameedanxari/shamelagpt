# Android ↔ iOS Test Parity Checklist
Updated: 2025-12-02 (PST)

## Unit tests
- [x] ChatViewModel (message flow, voice, OCR) – parity with iOS ChatViewModelTests; added OCR flow coverage.
- [x] OCRManager – mirrors iOS OCRManagerTests for success/error/language detection.
- [x] LanguageManager – matches iOS language preference coverage.
- [x] SendMessageUseCase – parity with iOS SendMessageUseCaseTests.
- [x] HistoryViewModel – parity with iOS HistoryViewModelTests.
- [x] Network/Parsing (ResponseParserTest, NetworkErrorTest, SafeApiCallTest, ChatRepositoryImplTest) – covers APIClient/Model plumbing from iOS suite.
- [ ] Domain models (Message/Conversation/Source equality helpers) – iOS ModelTests exist; add Android equivalents.
- [ ] VoiceInputManager direct unit tests – currently covered indirectly via ChatViewModel; add dedicated manager tests to mirror iOS VoiceInputManagerTests.

## Integration tests
- [x] MessageFlowIntegrationTest – parity with iOS MessageFlowIntegrationTests.
- [x] NetworkErrorRecoveryTest – parity with iOS NetworkErrorRecoveryTests.
- [x] FactCheckIntegrationTest – parity with iOS FactCheckIntegrationTests.

## UI/Instrumentation
- [ ] Android UI/instrumentation coverage for Chat/History/Voice/OCR/Settings – iOS UITests exist; add Espresso/Compose UI equivalents.

## Progress log
- 2025-12-02: Added OCRManagerTest, LanguageManagerTest, and OCR flow coverage in ChatViewModelTest to align with iOS OCR/Language test suites.
