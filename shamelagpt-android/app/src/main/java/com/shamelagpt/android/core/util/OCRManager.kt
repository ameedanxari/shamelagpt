package com.shamelagpt.android.core.util

import android.content.Context
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.TextRecognizer
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.tasks.await
import java.io.IOException

/**
 * Data class representing OCR result with text and detected language.
 *
 * @property text The recognized text
 * @property detectedLanguage ISO language code (e.g., "en", "ar") or null if unknown
 */
data class OCRResult(
    val text: String,
    val detectedLanguage: String?
)

/**
 * Manager class for handling OCR (Optical Character Recognition) using Google ML Kit.
 *
 * @property context Application context
 */
class OCRManager(
    private val context: Context,
    // Text recognizer is injected for testability (default ML Kit client in production)
    private val recognizer: TextRecognizer = TextRecognition.getClient(
        TextRecognizerOptions.DEFAULT_OPTIONS
    )
) {

    /**
     * Recognizes text from an image URI.
     *
     * @param imageUri URI of the image to process
     * @return Result containing the recognized text or an error
     */
    suspend fun recognizeText(imageUri: Uri): Result<String> {
        return recognizeTextWithLanguage(imageUri).map { it.text }
    }

    /**
     * Recognizes text from an image URI with language detection.
     *
     * @param imageUri URI of the image to process
     * @return Result containing OCRResult with text and detected language, or an error
     */
    suspend fun recognizeTextWithLanguage(imageUri: Uri): Result<OCRResult> {
        return try {
            Logger.d("OCR", "Starting OCR for image: $imageUri")

            // Create InputImage from URI
            val image = InputImage.fromFilePath(context, imageUri)
            Logger.d("OCR", "InputImage created successfully")

            // Process the image
            val result = recognizer.process(image).await()
            Logger.d("OCR", "OCR processing completed")

            // Extract text
            val recognizedText = result.text
            Logger.d("OCR", "Recognized text length: ${recognizedText.length}")

            if (recognizedText.isBlank()) {
                Logger.w("OCR", "No text found in image")
                Result.failure(Exception("No text found in image"))
            } else {
                // Detect language from text
                val detectedLanguage = detectLanguage(listOf(recognizedText))
                Logger.i("OCR", "OCR successful - Language: $detectedLanguage, Text preview: ${recognizedText.take(50)}")

                Result.success(OCRResult(recognizedText, detectedLanguage))
            }

        } catch (e: IOException) {
            Logger.e("OCR", "Failed to load image", e)
            Result.failure(Exception("Failed to load image: ${e.message}"))
        } catch (e: Exception) {
            Logger.e("OCR", "Text recognition failed", e)
            Result.failure(Exception("Text recognition failed: ${e.message}"))
        }
    }

    /**
     * Detects the predominant language from text blocks.
     * Uses simple heuristics based on character ranges.
     *
     * @param textBlocks List of text strings to analyze
     * @return ISO language code ("ar" for Arabic, "en" for English/Latin) or null if unknown
     */
    private fun detectLanguage(textBlocks: List<String>): String? {
        if (textBlocks.isEmpty()) return null

        val allText = textBlocks.joinToString(" ")
        if (allText.isBlank()) return null

        // Count Arabic vs Latin characters
        var arabicChars = 0
        var latinChars = 0

        for (char in allText) {
            when (char) {
                in '\u0600'..'\u06FF', // Arabic
                in '\u0750'..'\u077F', // Arabic Supplement
                in '\uFB50'..'\uFDFF', // Arabic Presentation Forms-A
                in '\uFE70'..'\uFEFF'  // Arabic Presentation Forms-B
                -> arabicChars++
                in 'A'..'Z', in 'a'..'z' -> latinChars++
            }
        }

        // Determine predominant script (need at least 10% threshold)
        val totalChars = arabicChars + latinChars
        if (totalChars == 0) return null

        val arabicRatio = arabicChars.toFloat() / totalChars
        val latinRatio = latinChars.toFloat() / totalChars

        return when {
            arabicRatio > 0.1 && arabicRatio > latinRatio -> "ar"
            latinRatio > 0.1 -> "en"
            else -> null
        }
    }

    /**
     * Recognizes text from an image URI with detailed block information.
     *
     * @param imageUri URI of the image to process
     * @return Result containing the recognized text with block structure or an error
     */
    suspend fun recognizeTextWithBlocks(imageUri: Uri): Result<List<TextBlockInfo>> {
        return try {
            // Create InputImage from URI
            val image = InputImage.fromFilePath(context, imageUri)

            // Process the image
            val result = recognizer.process(image).await()

            if (result.textBlocks.isEmpty()) {
                Result.failure(Exception("No text found in image"))
            } else {
                val textBlocks = result.textBlocks.map { block ->
                    TextBlockInfo(
                        text = block.text,
                        lines = block.lines.map { line -> line.text }
                    )
                }
                Result.success(textBlocks)
            }

        } catch (e: IOException) {
            Result.failure(Exception("Failed to load image: ${e.message}"))
        } catch (e: Exception) {
            Result.failure(Exception("Text recognition failed: ${e.message}"))
        }
    }

    /**
     * Closes the text recognizer and releases resources.
     * Should be called when the manager is no longer needed.
     */
    fun close() {
        try {
            recognizer.close()
        } catch (e: Exception) {
            // Ignore errors when closing
        }
    }

    /**
     * Data class representing a block of recognized text.
     *
     * @property text The recognized text in the block
     * @property lines Individual lines within the block
     */
    data class TextBlockInfo(
        val text: String,
        val lines: List<String>
    )
}
