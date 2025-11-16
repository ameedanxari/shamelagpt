package com.shamelagpt.android.data.mapper

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.shamelagpt.android.data.local.entity.MessageEntity
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.model.Source

/**
 * Converts MessageEntity to domain model Message.
 *
 * @return Message domain model
 */
fun MessageEntity.toDomain(): Message {
    val sourceList = sources?.let { jsonString ->
        try {
            val gson = Gson()
            val listType = object : TypeToken<List<Source>>() {}.type
            gson.fromJson<List<Source>>(jsonString, listType)
        } catch (e: Exception) {
            null
        }
    }

    return Message(
        id = id,
        content = content,
        isUserMessage = isUserMessage,
        timestamp = timestamp,
        sources = sourceList,
        imageData = imageData,
        detectedLanguage = detectedLanguage,
        isFactCheckMessage = isFactCheckMessage
    )
}

/**
 * Converts domain model Message to MessageEntity.
 *
 * @param conversationId ID of the conversation this message belongs to
 * @return MessageEntity for database storage
 */
fun Message.toEntity(conversationId: String): MessageEntity {
    val sourcesJson = sources?.let { sourceList ->
        try {
            val gson = Gson()
            gson.toJson(sourceList)
        } catch (e: Exception) {
            null
        }
    }

    return MessageEntity(
        id = id,
        conversationId = conversationId,
        content = content,
        isUserMessage = isUserMessage,
        timestamp = timestamp,
        sources = sourcesJson,
        imageData = imageData,
        detectedLanguage = detectedLanguage,
        isFactCheckMessage = isFactCheckMessage
    )
}
