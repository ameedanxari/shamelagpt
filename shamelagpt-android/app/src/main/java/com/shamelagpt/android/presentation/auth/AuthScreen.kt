package com.shamelagpt.android.presentation.auth

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.res.stringResource
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
import androidx.compose.ui.text.input.VisualTransformation
import com.shamelagpt.android.R
import com.shamelagpt.android.presentation.common.TestTags
import org.koin.androidx.compose.koinViewModel

import androidx.compose.ui.platform.testTag

@Composable
fun AuthScreen(
    onAuthenticated: () -> Unit,
    onContinueAsGuest: () -> Unit,
    viewModel: AuthViewModel = koinViewModel()
){
    val state by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
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
                autoCorrect = false
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
                autoCorrect = false
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
            onClick = { if (!state.isLoading) viewModel.authenticate(onAuthenticated) },
            enabled = !state.isLoading,
            modifier = Modifier.fillMaxWidth().testTag(if (state.isLoginMode) TestTags.Auth.SignInButton else TestTags.Auth.SignUpButton)
        ) {
            Text(if (state.isLoginMode) stringResource(R.string.sign_in) else stringResource(R.string.sign_up))
        }

        Spacer(modifier = Modifier.height(8.dp))

        OutlinedButton(
            onClick = onContinueAsGuest,
            enabled = !state.isLoading,
            modifier = Modifier.fillMaxWidth().testTag(TestTags.Auth.ContinueAsGuestButton)
        ) {
            Text(stringResource(R.string.continue_as_guest))
        }

        Spacer(modifier = Modifier.height(8.dp))

        TextButton(
            onClick = { viewModel.toggleMode() },
            modifier = Modifier.testTag(TestTags.Auth.ToggleModeButton)
        ) {
            Text(
                if (state.isLoginMode) stringResource(R.string.need_account) else stringResource(R.string.have_account)
            )
        }
    }
}
