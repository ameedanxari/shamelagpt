package com.shamelagpt.android.data.repository

import app.cash.turbine.test
import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.data.local.dao.ConversationDao
import com.shamelagpt.android.data.local.dao.ConversationWithLastMessageEntity
import com.shamelagpt.android.data.local.dao.MessageDao
import com.shamelagpt.android.data.local.entity.ConversationEntity
import com.shamelagpt.android.data.local.entity.ConversationType
import com.shamelagpt.android.data.local.entity.MessageEntity
import com.shamelagpt.android.data.mapper.toDomain
import com.shamelagpt.android.data.mapper.toEntity
import com.shamelagpt.android.mock.TestData
import com.shamelagpt.android.core.preferences.ConversationSyncMetadataStore
import com.shamelagpt.android.util.MainCoroutineRule
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.runs
import io.mockk.slot
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test

/**
 * Unit tests for ConversationRepositoryImpl.
 * Tests database operations and Flow emissions.
 */
@ExperimentalCoroutinesApi
class ConversationRepositoryImplTest {

    @get:Rule
    val mainCoroutineRule = MainCoroutineRule()

    private lateinit var conversationRepository: ConversationRepositoryImpl
    private lateinit var mockConversationDao: ConversationDao
    private lateinit var mockMessageDao: MessageDao
    private lateinit var mockSyncMetadataStore: ConversationSyncMetadataStore

    @Before
    fun setup() {
        mockConversationDao = mockk()
        mockMessageDao = mockk()
        mockSyncMetadataStore = mockk(relaxed = true)
        conversationRepository = ConversationRepositoryImpl(
            conversationDao = mockConversationDao,
            messageDao = mockMessageDao,
            syncMetadataStore = mockSyncMetadataStore
        )
    }

    // MARK: - Conversation CRUD Tests

    @Test
    fun testCreateConversation() = runTest {
        // Given
        val title = "Test Conversation"
        val conversationSlot = slot<ConversationEntity>()

        coEvery {
            mockConversationDao.insertConversation(capture(conversationSlot))
        } just runs

        // When
        val conversation = conversationRepository.createConversation(title)

        // Then
        assertThat(conversation.id).isNotEmpty()
        assertThat(conversation.title).isEqualTo(title)
        assertThat(conversation.threadId).isNull()
        assertThat(conversation.messages).isEmpty()
        assertThat(conversation.createdAt).isGreaterThan(0)
        assertThat(conversation.updatedAt).isEqualTo(conversation.createdAt)

        // Verify DAO was called
        coVerify { mockConversationDao.insertConversation(any()) }
        assertThat(conversationSlot.captured.title).isEqualTo(title)
    }

    @Test
    fun testGetConversationById() = runTest {
        // Given
        val conversationId = "conv-123"
        val entity = ConversationEntity(
            id = conversationId,
            threadId = "thread-abc",
            title = "Test",
            createdAt = System.currentTimeMillis(),
            updatedAt = System.currentTimeMillis(),
            conversationType = ConversationType.REGULAR.name
        )

        coEvery {
            mockConversationDao.getConversationById(conversationId)
        } returns entity

        // When
        val conversation = conversationRepository.getConversationById(conversationId)

        // Then
        assertThat(conversation).isNotNull()
        assertThat(conversation?.id).isEqualTo(conversationId)
        assertThat(conversation?.title).isEqualTo("Test")
        assertThat(conversation?.threadId).isEqualTo("thread-abc")
    }

    @Test
    fun testGetConversationByIdNotFound() = runTest {
        // Given
        val conversationId = "non-existent"

        coEvery {
            mockConversationDao.getConversationById(conversationId)
        } returns null

        // When
        val conversation = conversationRepository.getConversationById(conversationId)

        // Then
        assertThat(conversation).isNull()
    }

    @Test
    fun testGetAllConversationsFlow() = runTest {
        // Given
        val entity1 = TestData.sampleConversation.toEntity()
        val entity2 = TestData.sampleFactCheckConversation.toEntity()

        every {
            mockConversationDao.getAllConversations()
        } returns flowOf(listOf(
            ConversationWithLastMessageEntity(entity1, null, entity1.updatedAt),
            ConversationWithLastMessageEntity(entity2, null, entity2.updatedAt)
        ))

        // When/Then
        conversationRepository.getConversations().test {
            val conversations = awaitItem()
            assertThat(conversations).hasSize(2)
            assertThat(conversations[0].id).isEqualTo(entity1.id)
            assertThat(conversations[1].id).isEqualTo(entity2.id)
            awaitComplete()
        }
    }

    @Test
    fun testGetAllConversationsOrderedByUpdatedAt() = runTest {
        // Given - Entities ordered by updatedAt descending
        val now = System.currentTimeMillis()
        val entity1 = ConversationEntity(
            id = "conv-1",
            title = "Older",
            createdAt = now - 2000,
            updatedAt = now - 2000,
            conversationType = ConversationType.REGULAR.name
        )
        val entity2 = ConversationEntity(
            id = "conv-2",
            title = "Newer",
            createdAt = now - 1000,
            updatedAt = now - 1000,
            conversationType = ConversationType.REGULAR.name
        )

        every {
            mockConversationDao.getAllConversations()
        } returns flowOf(listOf(
            ConversationWithLastMessageEntity(entity2, null, entity2.updatedAt),
            ConversationWithLastMessageEntity(entity1, null, entity1.updatedAt)
        )) // Newer first

        // When/Then
        conversationRepository.getConversations().test {
            val conversations = awaitItem()
            // Should maintain order from DAO (which should be sorted)
            assertThat(conversations[0].id).isEqualTo("conv-2")
            assertThat(conversations[1].id).isEqualTo("conv-1")
            awaitComplete()
        }
    }

    @Test
    fun testDeleteConversation() = runTest {
        // Given
        val conversationId = "conv-123"
        val entity = TestData.sampleConversation.toEntity()

        coEvery {
            mockConversationDao.getConversationById(conversationId)
        } returns entity

        coEvery {
            mockConversationDao.deleteConversation(entity)
        } just runs

        // When
        conversationRepository.deleteConversation(conversationId)

        // Then
        coVerify { mockConversationDao.deleteConversation(entity) }
    }

    @Test
    fun testDeleteConversationCascadesMessages() = runTest {
        // Given - This is implicitly tested by Room's cascade delete
        val conversationId = "conv-123"
        val entity = TestData.sampleConversation.toEntity()

        coEvery {
            mockConversationDao.getConversationById(conversationId)
        } returns entity

        coEvery {
            mockConversationDao.deleteConversation(entity)
        } just runs

        // When
        conversationRepository.deleteConversation(conversationId)

        // Then
        // Messages are cascade deleted by Room due to foreign key constraint
        // Verify conversation was deleted
        coVerify { mockConversationDao.deleteConversation(entity) }
    }

    @Test
    fun testDeleteAllConversations() = runTest {
        // Given
        coEvery {
            mockConversationDao.deleteAllConversations()
        } just runs

        // When
        conversationRepository.deleteAllConversations()

        // Then
        coVerify { mockConversationDao.deleteAllConversations() }
    }

    // MARK: - Message CRUD Tests

    @Test
    fun testSaveMessage() = runTest {
        // Given
        val message = TestData.sampleUserMessage
        val conversationId = "conv-123"
        val conversationEntity = TestData.sampleConversation.toEntity()

        val messageSlot = slot<MessageEntity>()
        val conversationSlot = slot<ConversationEntity>()

        coEvery {
            mockMessageDao.insertMessage(capture(messageSlot))
        } just runs

        coEvery {
            mockConversationDao.getConversationById(conversationId)
        } returns conversationEntity

        coEvery {
            mockConversationDao.updateConversation(capture(conversationSlot))
        } just runs

        // When
        conversationRepository.saveMessage(message, conversationId)

        // Then
        coVerify { mockMessageDao.insertMessage(any()) }
        coVerify { mockConversationDao.updateConversation(any()) }

        // Verify message was saved correctly
        assertThat(messageSlot.captured.content).isEqualTo(message.content)
        assertThat(messageSlot.captured.conversationId).isEqualTo(conversationId)

        // Verify conversation timestamp was updated
        assertThat(conversationSlot.captured.updatedAt).isGreaterThan(conversationEntity.updatedAt)
    }

    @Test
    fun testGetMessagesByConversationIdFlow() = runTest {
        // Given
        val conversationId = "conv-123"
        val messageEntity1 = TestData.sampleUserMessage.toEntity(conversationId)
        val messageEntity2 = TestData.sampleAssistantMessage.toEntity(conversationId)

        every {
            mockMessageDao.getMessagesByConversationId(conversationId)
        } returns flowOf(listOf(messageEntity1, messageEntity2))

        // When/Then
        conversationRepository.getMessagesByConversationId(conversationId).test {
            val messages = awaitItem()
            assertThat(messages).hasSize(2)
            assertThat(messages[0].id).isEqualTo(messageEntity1.id)
            assertThat(messages[1].id).isEqualTo(messageEntity2.id)
            awaitComplete()
        }
    }

    @Test
    fun testGetMessagesByConversationIdOrderedByTimestamp() = runTest {
        // Given - Messages ordered by timestamp ascending
        val conversationId = "conv-123"
        val now = System.currentTimeMillis()

        val message1 = TestData.createMessage(
            id = "msg-1",
            content = "First",
            timestamp = now
        )
        val message2 = TestData.createMessage(
            id = "msg-2",
            content = "Second",
            timestamp = now + 1000
        )

        every {
            mockMessageDao.getMessagesByConversationId(conversationId)
        } returns flowOf(listOf(message1.toEntity(conversationId), message2.toEntity(conversationId)))

        // When/Then
        conversationRepository.getMessagesByConversationId(conversationId).test {
            val messages = awaitItem()
            assertThat(messages[0].content).isEqualTo("First")
            assertThat(messages[1].content).isEqualTo("Second")
            awaitComplete()
        }
    }

    @Test
    fun testSaveMessageUpdatesConversationTimestamp() = runTest {
        // Given
        val message = TestData.sampleUserMessage
        val conversationId = "conv-123"
        val oldTimestamp = System.currentTimeMillis() - 10000
        val conversationEntity = ConversationEntity(
            id = conversationId,
            title = "Test",
            createdAt = oldTimestamp,
            updatedAt = oldTimestamp,
            conversationType = ConversationType.REGULAR.name
        )

        val conversationSlot = slot<ConversationEntity>()

        coEvery {
            mockMessageDao.insertMessage(any())
        } just runs

        coEvery {
            mockConversationDao.getConversationById(conversationId)
        } returns conversationEntity

        coEvery {
            mockConversationDao.updateConversation(capture(conversationSlot))
        } just runs

        // When
        conversationRepository.saveMessage(message, conversationId)

        // Then - updatedAt should be newer than old timestamp
        assertThat(conversationSlot.captured.updatedAt).isGreaterThan(oldTimestamp)
    }

    @Test
    fun testSaveMessageWithImageData() = runTest {
        // Given
        val message = TestData.sampleFactCheckMessage
        val conversationId = "conv-123"
        val conversationEntity = TestData.sampleConversation.toEntity()

        val messageSlot = slot<MessageEntity>()

        coEvery {
            mockMessageDao.insertMessage(capture(messageSlot))
        } just runs

        coEvery {
            mockConversationDao.getConversationById(conversationId)
        } returns conversationEntity

        coEvery {
            mockConversationDao.updateConversation(any())
        } just runs

        // When
        conversationRepository.saveMessage(message, conversationId)

        // Then - imageData should be preserved
        assertThat(messageSlot.captured.imageData).isNotNull()
        assertThat(messageSlot.captured.imageData).isEqualTo(message.imageData)
    }

    @Test
    fun testSaveMessageWithDetectedLanguage() = runTest {
        // Given
        val message = TestData.sampleFactCheckMessage.copy(detectedLanguage = "ar")
        val conversationId = "conv-123"
        val conversationEntity = TestData.sampleConversation.toEntity()

        val messageSlot = slot<MessageEntity>()

        coEvery {
            mockMessageDao.insertMessage(capture(messageSlot))
        } just runs

        coEvery {
            mockConversationDao.getConversationById(conversationId)
        } returns conversationEntity

        coEvery {
            mockConversationDao.updateConversation(any())
        } just runs

        // When
        conversationRepository.saveMessage(message, conversationId)

        // Then
        assertThat(messageSlot.captured.detectedLanguage).isEqualTo("ar")
    }

    @Test
    fun testSaveMessageWithFactCheckFlag() = runTest {
        // Given
        val message = TestData.sampleFactCheckMessage
        val conversationId = "conv-123"
        val conversationEntity = TestData.sampleConversation.toEntity()

        val messageSlot = slot<MessageEntity>()

        coEvery {
            mockMessageDao.insertMessage(capture(messageSlot))
        } just runs

        coEvery {
            mockConversationDao.getConversationById(conversationId)
        } returns conversationEntity

        coEvery {
            mockConversationDao.updateConversation(any())
        } just runs

        // When
        conversationRepository.saveMessage(message, conversationId)

        // Then
        assertThat(messageSlot.captured.isFactCheckMessage).isTrue()
    }

    // MARK: - Update Thread ID Tests

    @Test
    fun testUpdateConversationThread() = runTest {
        // Given
        val conversationId = "conv-123"
        val newThreadId = "thread-xyz-789"
        val conversationEntity = TestData.sampleConversation.toEntity()

        val conversationSlot = slot<ConversationEntity>()

        coEvery {
            mockConversationDao.getConversationById(conversationId)
        } returns conversationEntity

        coEvery {
            mockConversationDao.updateConversation(capture(conversationSlot))
        } just runs

        // When
        conversationRepository.updateConversationThread(conversationId, newThreadId)

        // Then
        assertThat(conversationSlot.captured.threadId).isEqualTo(newThreadId)
        assertThat(conversationSlot.captured.updatedAt).isGreaterThan(conversationEntity.updatedAt)
    }
}
