package com.shamelagpt.android.presentation.auth

import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.width
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.shamelagpt.android.R
import com.shamelagpt.android.presentation.common.TestTags
import kotlinx.coroutines.launch
import org.koin.androidx.compose.koinViewModel

import androidx.compose.ui.platform.testTag

@Composable
fun AuthScreen(
    onAuthenticated: () -> Unit,
    onContinueAsGuest: () -> Unit,
    viewModel: AuthViewModel = koinViewModel()
){
    val state by viewModel.uiState.collectAsState()
    val focusManager = LocalFocusManager.current
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
            .pointerInput(Unit) {
                detectTapGestures(onTap = { focusManager.clearFocus(force = true) })
            }
            .testTag(TestTags.Auth.Screen),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = if (state.isLoginMode) stringResource(R.string.sign_in) else stringResource(R.string.create_account),
            style = MaterialTheme.typography.headlineSmall,
            modifier = Modifier.testTag(TestTags.Auth.Title)
        )

        Spacer(modifier = Modifier.height(16.dp))


        var passwordVisible by remember { mutableStateOf(false) }

        OutlinedTextField(
            value = state.email,
            onValueChange = viewModel::updateEmail,
            label = { Text(stringResource(R.string.email)) },
            modifier = Modifier.fillMaxWidth().testTag(TestTags.Auth.EmailField),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Email,
                autoCorrectEnabled = false
            ),
            singleLine = true
        )

        Spacer(modifier = Modifier.height(8.dp))

        OutlinedTextField(
            value = state.password,
            onValueChange = viewModel::updatePassword,
            label = { Text(stringResource(R.string.password)) },
            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth().testTag(TestTags.Auth.PasswordField),
            trailingIcon = {
                val image = if (passwordVisible)
                    Icons.Filled.Visibility
                else Icons.Filled.VisibilityOff

                val description = if (passwordVisible) "Hide password" else "Show password"

                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                    Icon(imageVector = image, description)
                }
            },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                autoCorrectEnabled = false
            ),
            singleLine = true
        )

        if (!state.isLoginMode) {
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = state.displayName,
                onValueChange = viewModel::updateDisplayName,
                label = { Text(stringResource(R.string.display_name_optional)) },
                modifier = Modifier.fillMaxWidth().testTag(TestTags.Auth.DisplayNameField)
            )
        }

        if (state.error != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = state.error ?: "",
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.testTag(TestTags.Auth.ErrorLabel)
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            onClick = {
                if (!state.isLoading) {
                    focusManager.clearFocus(force = true)
                    viewModel.authenticate(onAuthenticated)
                }
            },
            enabled = !state.isLoading,
            modifier = Modifier.fillMaxWidth().testTag(if (state.isLoginMode) TestTags.Auth.SignInButton else TestTags.Auth.SignUpButton)
        ) {
            Text(if (state.isLoginMode) stringResource(R.string.sign_in) else stringResource(R.string.sign_up))
        }

        Spacer(modifier = Modifier.height(8.dp))

        // "or" divider
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            HorizontalDivider(modifier = Modifier.weight(1f))
            Text(
                text = stringResource(R.string.auth_or_divider),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 16.dp)
            )
            HorizontalDivider(modifier = Modifier.weight(1f))
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Google Sign-In button
        Button(
            onClick = {
                focusManager.clearFocus(force = true)
                val credentialManager = CredentialManager.create(context)
                val googleIdOption = GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(context.getString(R.string.google_web_client_id))
                    .build()
                val request = GetCredentialRequest.Builder()
                    .addCredentialOption(googleIdOption)
                    .build()

                scope.launch {
                    try {
                        val result = credentialManager.getCredential(
                            context = context as android.app.Activity,
                            request = request
                        )
                        val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(result.credential.data)
                        viewModel.googleSignIn(googleIdTokenCredential.idToken, onAuthenticated)
                    } catch (_: GetCredentialCancellationException) {
                        // User cancelled — do nothing
                    } catch (e: Exception) {
                        viewModel.setError(context.getString(R.string.google_sign_in_failed))
                    }
                }
            },
            enabled = !state.isLoading,
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp)
                .border(
                    width = 1.dp,
                    color = Color(0xFFDADCE0),
                    shape = RoundedCornerShape(4.dp)
                )
                .testTag(TestTags.Auth.GoogleSignInButton),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color.White,
                contentColor = Color(0xFF3C4043),
                disabledContainerColor = Color(0xFFF1F3F4),
                disabledContentColor = Color(0xFF9AA0A6)
            ),
            shape = RoundedCornerShape(4.dp),
            elevation = ButtonDefaults.buttonElevation(
                defaultElevation = 0.dp,
                pressedElevation = 2.dp
            )
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                Icon(
                    painter = painterResource(R.drawable.ic_google_logo),
                    contentDescription = "Google",
                    modifier = Modifier.size(18.dp),
                    tint = Color.Unspecified
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = stringResource(R.string.sign_in_with_google),
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Medium
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        OutlinedButton(
            onClick = {
                focusManager.clearFocus(force = true)
                onContinueAsGuest()
            },
            enabled = !state.isLoading,
            modifier = Modifier.fillMaxWidth().testTag(TestTags.Auth.ContinueAsGuestButton)
        ) {
            Text(stringResource(R.string.continue_as_guest))
        }

        Spacer(modifier = Modifier.height(8.dp))

        TextButton(
            onClick = {
                focusManager.clearFocus(force = true)
                viewModel.toggleMode()
            },
            modifier = Modifier.testTag(TestTags.Auth.ToggleModeButton)
        ) {
            Text(
                if (state.isLoginMode) stringResource(R.string.need_account) else stringResource(R.string.have_account)
            )
        }
    }
}
