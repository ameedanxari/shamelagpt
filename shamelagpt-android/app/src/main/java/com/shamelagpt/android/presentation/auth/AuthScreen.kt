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
import com.shamelagpt.android.R
import org.koin.androidx.compose.koinViewModel

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
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = if (state.isLoginMode) stringResource(R.string.sign_in) else stringResource(R.string.create_account),
            style = MaterialTheme.typography.headlineSmall
        )

        Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(
            value = state.email,
            onValueChange = viewModel::updateEmail,
            label = { Text(stringResource(R.string.email)) },
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(8.dp))

        OutlinedTextField(
            value = state.password,
            onValueChange = viewModel::updatePassword,
            label = { Text(stringResource(R.string.password)) },
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth()
        )

        if (!state.isLoginMode) {
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = state.displayName,
                onValueChange = viewModel::updateDisplayName,
                label = { Text(stringResource(R.string.display_name_optional)) },
                modifier = Modifier.fillMaxWidth()
            )
        }

        if (state.error != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = state.error ?: "",
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodyMedium
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            onClick = { if (!state.isLoading) viewModel.authenticate(onAuthenticated) },
            enabled = !state.isLoading,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(if (state.isLoginMode) stringResource(R.string.sign_in) else stringResource(R.string.sign_up))
        }

        Spacer(modifier = Modifier.height(8.dp))

        OutlinedButton(
            onClick = onContinueAsGuest,
            enabled = !state.isLoading,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(stringResource(R.string.continue_as_guest))
        }

        Spacer(modifier = Modifier.height(8.dp))

        TextButton(onClick = { viewModel.toggleMode() }) {
            Text(
                if (state.isLoginMode) stringResource(R.string.need_account) else stringResource(R.string.have_account)
            )
        }
    }
}
