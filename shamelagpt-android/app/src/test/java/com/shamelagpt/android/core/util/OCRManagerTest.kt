package com.shamelagpt.android.core.util

import android.content.Context
import android.net.Uri
import com.google.android.gms.tasks.Tasks
import com.google.common.truth.Truth.assertThat
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.Text.TextBlock
import com.google.mlkit.vision.text.Text.Line
import com.google.mlkit.vision.text.TextRecognizer
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.unmockkAll
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Test
import java.io.IOException

@org.junit.Ignore("Mocking final ML Kit classes is unstable in plain unit tests")
@ExperimentalCoroutinesApi
class OCRManagerTest {

    private lateinit var mockContext: Context
    private lateinit var mockRecognizer: TextRecognizer
    private lateinit var ocrManager: OCRManager

    @Before
    fun setUp() {
        mockkStatic(Uri::class)
        mockkStatic(InputImage::class)
        mockkStatic(Text::class)
        mockkStatic(Text.TextBlock::class)
        mockkStatic(Text.Line::class)

        every { Uri.parse(any()) } returns mockk(relaxed = true)
        
        mockContext = mockk(relaxed = true)
        mockRecognizer = mockk(relaxed = true)
        ocrManager = OCRManager(mockContext, mockRecognizer)
    }

    @After
    fun tearDown() {
        unmockkAll()
    }

    @org.junit.Ignore("Mocking final ML Kit classes is unstable in plain unit tests")
    @Test
    fun recognizeTextWithLanguageReturnsLanguageAndText() = runTest {
        // Given
        val imageUri = Uri.parse("content://test/image")
        val mockImage = mockInputImage(imageUri)
        val textResult = createTextResult(
            fullText = "Hello world",
            blocks = listOf("Hello world" to listOf("Hello world"))
        )
        every { mockRecognizer.process(mockImage) } returns Tasks.forResult(textResult)

        // When
        val result = ocrManager.recognizeTextWithLanguage(imageUri)

        // Then
        assertThat(result.isSuccess).isTrue()
        val ocrResult = result.getOrThrow()
        assertThat(ocrResult.text).isEqualTo("Hello world")
        assertThat(ocrResult.detectedLanguage).isEqualTo("en")
    }

    @org.junit.Ignore("Mocking final ML Kit classes is unstable in plain unit tests")
    @Test
    fun recognizeTextWithLanguageFailsWhenNoTextFound() = runTest {
        // Given
        val imageUri = Uri.parse("content://test/empty")
        val mockImage = mockInputImage(imageUri)
        val emptyResult = createTextResult(fullText = "", blocks = emptyList())
        every { mockRecognizer.process(mockImage) } returns Tasks.forResult(emptyResult)

        // When
        val result = ocrManager.recognizeTextWithLanguage(imageUri)

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()?.message).contains("No text found")
    }

    @Test
    fun recognizeTextWithLanguageHandlesRecognizerFailure() = runTest {
        // Given
        val imageUri = Uri.parse("content://test/error")
        val mockImage = mockInputImage(imageUri)
        every { mockRecognizer.process(mockImage) } returns Tasks.forException(
            RuntimeException("Recognizer error")
        )

        // When
        val result = ocrManager.recognizeTextWithLanguage(imageUri)

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()?.message).contains("Text recognition failed")
    }

    @Test
    fun recognizeTextWithLanguageHandlesImageLoadFailure() = runTest {
        // Given
        val imageUri = Uri.parse("content://test/bad-image")
        mockkStatic(InputImage::class)
        every { InputImage.fromFilePath(any(), imageUri) } throws IOException("bad image")

        // When
        val result = ocrManager.recognizeTextWithLanguage(imageUri)

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()?.message).contains("Failed to load image")
    }

    @org.junit.Ignore("Mocking final ML Kit classes is unstable in plain unit tests")
    @Test
    fun recognizeTextWithBlocksReturnsStructuredContent() = runTest {
        // Given
        val imageUri = Uri.parse("content://test/blocks")
        val mockImage = mockInputImage(imageUri)

        val block1 = createTextBlock("First block", listOf("First block line"))
        val block2 = createTextBlock("Second block", listOf("Second block line"))
        val textResult = mockk<Text> {
            every { textBlocks } returns listOf(block1, block2)
            every { text } returns "First block\nSecond block"
        }

        every { mockRecognizer.process(mockImage) } returns Tasks.forResult(textResult)

        // When
        val result = ocrManager.recognizeTextWithBlocks(imageUri)

        // Then
        assertThat(result.isSuccess).isTrue()
        val blocks = result.getOrThrow()
        assertThat(blocks).hasSize(2)
        assertThat(blocks[0].text).isEqualTo("First block")
        assertThat(blocks[0].lines).containsExactly("First block line")
    }

    private fun mockInputImage(imageUri: Uri): InputImage {
        val mockImage = mockk<InputImage>()
        every { InputImage.fromFilePath(any(), imageUri) } returns mockImage
        return mockImage
    }

    private fun createTextResult(
        fullText: String,
        blocks: List<Pair<String, List<String>>>
    ): Text {
        val textResult = mockk<Text>(relaxed = true)
        every { textResult.text } returns fullText
        return textResult
    }

    private fun createTextBlock(textValue: String, linesList: List<String>): TextBlock {
        return mockk<TextBlock>(relaxed = true)
    }
}
