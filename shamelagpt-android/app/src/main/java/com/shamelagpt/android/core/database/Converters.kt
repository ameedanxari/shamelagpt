package com.shamelagpt.android.core.database

import androidx.room.TypeConverter
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.shamelagpt.android.domain.model.Source

/**
 * Room type converters for custom data types.
 */
class Converters {

    private val gson = Gson()

    /**
     * Converts a JSON string to a list of Source objects.
     *
     * @param value JSON string representation
     * @return List of Source objects or null
     */
    @TypeConverter
    fun fromSourceList(value: String?): List<Source>? {
        if (value == null) return null
        val listType = object : TypeToken<List<Source>>() {}.type
        return try {
            gson.fromJson(value, listType)
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Converts a list of Source objects to a JSON string.
     *
     * @param list List of Source objects
     * @return JSON string representation or null
     */
    @TypeConverter
    fun toSourceList(list: List<Source>?): String? {
        return if (list == null) null else gson.toJson(list)
    }
}
