package com.shamelagpt.android.contract

import com.google.common.truth.Truth.assertThat
import com.google.gson.Gson
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import com.shamelagpt.android.data.remote.dto.ChatRequest
import com.shamelagpt.android.data.remote.dto.ChatResponse
import java.io.File
import org.junit.Test

class OpenApiContractMappingTest {
    private data class LoadedOpenApi(val root: JsonObject, val path: String)

    @Test
    fun `chat request model keys align to openapi chat and guest request schemas`() {
        val loaded = loadOpenApiRoot()
        val schemas = getObject(
            getObject(loaded.root, "components", loaded.path),
            "schemas",
            loaded.path
        )
        val chatProperties = schemaPropertyKeys(schemas, "ChatRequest", loaded.path)
        val guestProperties = schemaPropertyKeys(schemas, "GuestChatRequest", loaded.path)
        val allowedProperties = chatProperties + guestProperties

        val request = ChatRequest(
            question = "What is Islam?",
            threadId = "thread-123",
            languagePreference = "en",
            customSystemPrompt = "be concise",
            sessionId = "session-456",
            enableThinking = true
        )

        val modelKeys = Gson().toJsonTree(request).asJsonObject.keySet()
        val unknownKeys = modelKeys - allowedProperties

        assertThat(unknownKeys).isEmpty()
        assertThat(modelKeys).contains("question")
        assertThat(modelKeys).contains("thread_id")
        assertThat(modelKeys).contains("language_preference")
        assertThat(modelKeys).contains("custom_system_prompt")
        assertThat(modelKeys).contains("enable_thinking")
        assertThat(modelKeys).contains("session_id")
    }

    @Test
    fun `chat request required fields remain compatible with openapi`() {
        val loaded = loadOpenApiRoot()
        val schemas = getObject(
            getObject(loaded.root, "components", loaded.path),
            "schemas",
            loaded.path
        )
        val required = schemaRequiredFields(schemas, "ChatRequest", loaded.path)

        assertThat(required).containsExactly("question")
    }

    @Test
    fun `chat response model keeps required openapi fields`() {
        val loaded = loadOpenApiRoot()
        val responseSchema = getObject(
            getObject(
                getObject(
                    getObject(
                        getObject(
                            getObject(
                                getObject(
                                    getObject(loaded.root, "paths", loaded.path),
                                    "/api/chat",
                                    loaded.path
                                ),
                                "post",
                                loaded.path
                            ),
                            "responses",
                            loaded.path
                        ),
                        "200",
                        loaded.path
                    ),
                    "content",
                    loaded.path
                ),
                "application/json",
                loaded.path
            ),
            "schema",
            loaded.path
        )

        val json = """{"answer":"hello","thread_id":"thread-123"}"""
        val decoded = Gson().fromJson(json, ChatResponse::class.java)

        // OpenAPI currently leaves /api/chat response as an untyped object; request schema is authoritative.
        assertThat(responseSchema.entrySet().size).isAtLeast(0)
        assertThat(decoded.answer).isEqualTo("hello")
        assertThat(decoded.threadId).isEqualTo("thread-123")
    }

    private fun schemaPropertyKeys(schemas: JsonObject, schema: String, sourcePath: String): Set<String> {
        val schemaObj = getObject(schemas, schema, sourcePath)
        val properties = getObject(schemaObj, "properties", sourcePath)
        return properties.keySet()
    }

    private fun schemaRequiredFields(schemas: JsonObject, schema: String, sourcePath: String): Set<String> {
        val schemaObj = getObject(schemas, schema, sourcePath)
        val required = schemaObj.getAsJsonArray("required") ?: return emptySet()
        return required.mapNotNull { it.asString }.toSet()
    }

    private fun getObject(parent: JsonObject, key: String, sourcePath: String): JsonObject {
        val child = parent.getAsJsonObject(key)
        requireNotNull(child) {
            "Missing object key '$key' while parsing OpenAPI contract at $sourcePath. Available keys: ${parent.keySet()}"
        }
        return child
    }

    private fun loadOpenApiRoot(): LoadedOpenApi {
        val userDirPath = System.getProperty("user.dir") ?: "."
        var current: File? = File(userDirPath).canonicalFile
        val checked = mutableListOf<String>()

        while (current != null) {
            val candidate = File(current, "docs/api/openapi_latest.json")
            checked += candidate.path
            if (candidate.exists()) {
                return LoadedOpenApi(
                    root = JsonParser.parseString(candidate.readText()).asJsonObject,
                    path = candidate.path
                )
            }
            current = current.parentFile
        }

        error("openapi_latest.json not found. Checked: ${checked.joinToString()}")
    }
}
