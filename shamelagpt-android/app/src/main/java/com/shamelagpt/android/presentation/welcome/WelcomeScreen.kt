package com.shamelagpt.android.presentation.welcome

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Book
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.R

@Composable
fun WelcomeScreen(
    onGetStarted: () -> Unit,
    onSkipToChat: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(40.dp))

            // App Logo
            Icon(
                imageVector = Icons.Default.Book,
                contentDescription = "ShamelaGPT Logo",
                modifier = Modifier.size(120.dp),
                tint = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Welcome Title
            Text(
                text = "🌿 Welcome to ShamelaGPT",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Welcome Message
            Text(
                text = """ShamelaGPT is built upon the vast and trusted library of Shamela.ws, bringing authentic Islamic knowledge closer to everyone.
Our mission is to make reliable, reference-based information accessible in a natural and conversational way — across languages, backgrounds, and levels of understanding.

Whether you seek deeper insight, quick clarifications, or evidence-backed answers to common misconceptions, ShamelaGPT helps you explore Islam's rich heritage with accuracy, respect, and ease.

"Seek knowledge from the cradle to the grave." — Let this be your companion on that journey.""",
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Start,
                color = MaterialTheme.colorScheme.onSurface,
                lineHeight = MaterialTheme.typography.bodyLarge.lineHeight
            )

            Spacer(modifier = Modifier.height(32.dp))

            HorizontalDivider(modifier = Modifier.fillMaxWidth())

            Spacer(modifier = Modifier.height(32.dp))

            // Sign In Section
            Text(
                text = "🔐 Sign In for a Better Experience",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = """Log in to save your conversations, revisit your past questions, and share meaningful discussions with others.
Creating an account also helps us improve your learning experience — personalizing insights, language preferences, and reference trails for you.

👉 Sign in now and continue your journey of knowledge with consistency and clarity.""",
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Start,
                color = MaterialTheme.colorScheme.onSurface,
                lineHeight = MaterialTheme.typography.bodyLarge.lineHeight
            )

            Spacer(modifier = Modifier.weight(1f))
            Spacer(modifier = Modifier.height(24.dp))

            // Get Started Button
            Button(
                onClick = onGetStarted,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Text(
                    text = "Get Started",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Skip to Chat Button
            TextButton(
                onClick = onSkipToChat,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "Skip to Chat",
                    style = MaterialTheme.typography.bodyLarge
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
