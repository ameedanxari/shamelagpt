//
//  StreamingMessageHandler.swift
//  ShamelaGPT
//

import Foundation

/**
 * Events received during a chat stream.
 */
enum StreamEvent {
    case metadata(threadId: String)
    case thinking(String)
    case chunk(String)
    case done(fullAnswer: String?)
    case error(Error)
}

/**
 * Protocol for handling streaming message responses from the API.
 */
protocol StreamingMessageHandlerProtocol {
    /**
     * Consumes a raw string stream (typically from SSE) and yields structured StreamEvents.
     */
    func handleStream(_ stream: AsyncThrowingStream<String, Error>) async throws -> AsyncThrowingStream<StreamEvent, Error>
}

/**
 * Implementation of StreamingMessageHandler that parses SSE events.
 */
class StreamingMessageHandler: StreamingMessageHandlerProtocol {
    
    func handleStream(_ stream: AsyncThrowingStream<String, Error>) async throws -> AsyncThrowingStream<StreamEvent, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                var eventBuffer: [String] = []
                
                do {
                    for try await line in stream {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if trimmed.isEmpty {
                            if !eventBuffer.isEmpty {
                                processEventLines(eventBuffer, continuation: continuation)
                                eventBuffer.removeAll()
                            }
                        } else {
                            eventBuffer.append(line)
                            
                            // Handle cases where servers send JSON on single lines without blank delimiters
                            let isCompletePayload = (trimmed.hasPrefix("{") && trimmed.hasSuffix("}")) || 
                                                    (trimmed.hasPrefix("data:") && trimmed.hasSuffix("}"))
                            
                            if isCompletePayload {
                                // Preliminary check to see if it's a complete JSON. 
                                // Simple heuristic: if it has both { and } it might be a complete event.
                                // For robust SSE, a blank line is the true delimiter, but we support both.
                                processEventLines(eventBuffer, continuation: continuation)
                                eventBuffer.removeAll()
                            }
                        }
                    }
                    
                    if !eventBuffer.isEmpty {
                        processEventLines(eventBuffer, continuation: continuation)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private struct RawStreamEvent: Decodable {
        let type: String
        let content: String?
        let sessionId: String?
        let threadId: String?
        let fullAnswer: String?
    }

    private func processEventLines(_ lines: [String], continuation: AsyncThrowingStream<StreamEvent, Error>.Continuation) {
        // Collect all 'data:' payload lines from this event
        let payloadLines = lines.compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if trimmed.hasPrefix("data:") {
                let start = trimmed.index(trimmed.startIndex, offsetBy: 5)
                return String(trimmed[start...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            return nil
        }
        
        guard !payloadLines.isEmpty else { return }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Strategy: Some SSE servers send multiple JSON objects in a single 'data:' block,
        // while others send one JSON object spread across multiple 'data:' lines.
        // We first try parsing each line individually.
        for line in payloadLines {
            if line == "[DONE]" { continue }
            
            guard let data = line.data(using: .utf8) else { continue }
            
            do {
                let rawEvent = try decoder.decode(RawStreamEvent.self, from: data)
                yieldEvent(rawEvent, continuation: continuation)
            } catch {
                // If single-line parse fails, it might be a multi-line JSON.
                // We'll try concatenating all lines and parsing the whole block.
                let combined = payloadLines.joined(separator: "")
                if let combinedData = combined.data(using: .utf8) {
                    if let rawEvent = try? decoder.decode(RawStreamEvent.self, from: combinedData) {
                        yieldEvent(rawEvent, continuation: continuation)
                        return // Exit after parsing combined block to avoid duplicate yields
                    }
                }
                AppLogger.network.logDebug("Failed to parse SSE data: \(line.prefix(100))...")
            }
        }
    }

    private func yieldEvent(_ rawEvent: RawStreamEvent, continuation: AsyncThrowingStream<StreamEvent, Error>.Continuation) {
        switch rawEvent.type {
        case "metadata":
            if let tid = rawEvent.threadId ?? rawEvent.sessionId {
                continuation.yield(.metadata(threadId: tid))
            }
        case "thinking":
            if let text = rawEvent.content?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), !text.isEmpty {
                continuation.yield(.thinking(text))
            }
        case "chunk":
            continuation.yield(.chunk(rawEvent.content ?? ""))
        case "done":
            continuation.yield(.done(fullAnswer: rawEvent.fullAnswer ?? rawEvent.content))
        default:
            break
        }
    }
}
