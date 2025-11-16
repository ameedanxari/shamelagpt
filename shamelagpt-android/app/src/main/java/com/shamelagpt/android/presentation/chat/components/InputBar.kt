package com.shamelagpt.android.presentation.chat.components

import android.Manifest
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.presentation.components.isPermissionGranted
import androidx.compose.ui.res.stringResource
import com.shamelagpt.android.R
import com.shamelagpt.android.presentation.common.TestTags

import androidx.compose.ui.platform.testTag

/**
 * Input bar component with text field and action buttons.
 *
 * @param text Current input text
 * @param onTextChange Callback when text changes
 * @param onSendClick Callback when send button is clicked
 * @param isLoading Whether the app is currently loading (disables input)
 * @param isRecording Whether voice recording is active
 * @param isProcessingImage Whether image OCR is processing
 * @param onVoiceClick Callback when microphone button is clicked
 * @param onImageClick Callback when image/camera button is clicked with URI
 * @param modifier Modifier for the input bar
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InputBar(
    text: String,
    onTextChange: (String) -> Unit,
    onSendClick: () -> Unit,
    isLoading: Boolean,
    isRecording: Boolean = false,
    isProcessingImage: Boolean = false,
    requiresMicPermission: Boolean = true,
    onVoiceClick: () -> Unit = {},
    onImageClick: (Uri) -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var showImagePicker by remember { mutableStateOf(false) }

    // Image picker launcher
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { onImageClick(it) }
    }

    // Camera launcher
    var capturedImageUri by remember { mutableStateOf<Uri?>(null) }
    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        if (success) {
            capturedImageUri?.let { onImageClick(it) }
        }
    }

    // Permission launchers

    val micPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            onVoiceClick()
        }
    }

    Surface(
        modifier = modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 3.dp,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 8.dp),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Image/Camera button
            IconButton(
                onClick = { showImagePicker = true },
                enabled = !isLoading && !isRecording && !isProcessingImage,
                modifier = Modifier.testTag(TestTags.Chat.CameraButton)
            ) {
                if (isProcessingImage) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Add image",
                        tint = if (isLoading || isRecording) {
                            MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f)
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        }
                    )
                }
            }

            // Mic button with recording indicator
            IconButton(
                onClick = {
                    if (!requiresMicPermission) {
                        onVoiceClick()
                    } else if (context.isPermissionGranted(Manifest.permission.RECORD_AUDIO)) {
                        onVoiceClick()
                    } else {
                        micPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                    }
                },
                enabled = !isLoading && !isProcessingImage,
                modifier = Modifier.testTag(TestTags.Chat.MicButton)
            ) {
                if (isRecording) {
                    RecordingIndicator()
                } else {
                    Icon(
                        imageVector = Icons.Default.KeyboardVoice,
                        contentDescription = "Voice input",
                        tint = if (isLoading || isProcessingImage) {
                            MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f)
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        }
                    )
                }
            }

            // Text field
            OutlinedTextField(
                value = text,
                onValueChange = onTextChange,
                modifier = Modifier.weight(1f).testTag(TestTags.Chat.MessageInputField),
                placeholder = {
                    Text(
                        text = stringResource(R.string.chat_placeholder),
                        style = MaterialTheme.typography.bodyMedium
                    )
                },
                shape = RoundedCornerShape(24.dp),
                colors = TextFieldDefaults.outlinedTextFieldColors(
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                    disabledBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.38f)
                ),
                maxLines = 5,
                enabled = !isLoading && !isRecording,
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.Sentences,
                    imeAction = ImeAction.Send
                ),
                keyboardActions = KeyboardActions(
                    onSend = {
                        if (text.isNotBlank() && !isLoading && !isRecording) {
                            onSendClick()
                        }
                    }
                ),
                textStyle = MaterialTheme.typography.bodyMedium
            )

            // Send button
            IconButton(
                onClick = onSendClick,
                enabled = text.isNotBlank() && !isLoading && !isRecording && !isProcessingImage,
                modifier = Modifier.testTag(TestTags.Chat.SendButton)
            ) {
                Icon(
                    imageVector = Icons.Default.Send,
                    contentDescription = "Send message",
                    tint = if (text.isNotBlank() && !isLoading && !isRecording && !isProcessingImage) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f)
                    }
                )
            }
        }
    }

    // Image picker bottom sheet
    if (showImagePicker) {
        ImagePickerDialog(
            onDismiss = { showImagePicker = false },
            onCameraClick = {
                showImagePicker = false
                val uri = createImageUri(context)
                capturedImageUri = uri
                cameraLauncher.launch(uri)
            },
            onGalleryClick = {
                showImagePicker = false
                imagePickerLauncher.launch("image/*")
            }
        )
    }
}

/**
 * Recording indicator animation component.
 */
@Composable
fun RecordingIndicator() {
    val infiniteTransition = rememberInfiniteTransition(label = "recording")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.3f,
        animationSpec = infiniteRepeatable(
            animation = tween(600, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Icon(
        imageVector = Icons.Default.Mic,
        contentDescription = "Recording",
        tint = MaterialTheme.colorScheme.error,
        modifier = Modifier.graphicsLayer {
            scaleX = scale
            scaleY = scale
        }
    )
}

/**
 * Image picker dialog with camera and gallery options.
 */
@Composable
fun ImagePickerDialog(
    onDismiss: () -> Unit,
    onCameraClick: () -> Unit,
    onGalleryClick: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Image Source") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                TextButton(
                    onClick = onCameraClick,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        imageVector = Icons.Default.Camera,
                        contentDescription = null,
                        modifier = Modifier.padding(end = 8.dp)
                    )
                    Text("Take Photo")
                }
                TextButton(
                    onClick = onGalleryClick,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        imageVector = Icons.Default.PhotoLibrary,
                        contentDescription = null,
                        modifier = Modifier.padding(end = 8.dp)
                    )
                    Text("Choose from Gallery")
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

/**
 * Creates a temporary URI for capturing camera images.
 */
private fun createImageUri(context: android.content.Context): Uri {
    val directory = java.io.File(context.cacheDir, "images")
    directory.mkdirs()
    val file = java.io.File.createTempFile(
        "captured_image_${System.currentTimeMillis()}",
        ".jpg",
        directory
    )
    return androidx.core.content.FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        file
    )
}
