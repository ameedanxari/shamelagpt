package com.shamelagpt.android.presentation.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/**
 * Loading state components with animations for better UX.
 */

/**
 * Skeleton loader for conversation cards and other list items.
 *
 * @param modifier Modifier for the skeleton box
 */
@Composable
fun SkeletonLoader(modifier: Modifier = Modifier) {
    val infiniteTransition = rememberInfiniteTransition(label = "skeleton")
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 0.7f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "skeleton_alpha"
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(80.dp)
            .background(
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = alpha),
                RoundedCornerShape(12.dp)
            )
    )
}

/**
 * Shimmer loading effect for more sophisticated loading states.
 *
 * @param modifier Modifier for the shimmer box
 */
@Composable
fun ShimmerBox(modifier: Modifier = Modifier) {
    val infiniteTransition = rememberInfiniteTransition(label = "shimmer")
    val offset by infiniteTransition.animateFloat(
        initialValue = -1f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmer_offset"
    )

    val shimmerColor = MaterialTheme.colorScheme.surfaceVariant
    val highlightColor = MaterialTheme.colorScheme.surface

    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(
                brush = Brush.horizontalGradient(
                    colors = listOf(
                        shimmerColor,
                        highlightColor,
                        shimmerColor
                    ),
                    startX = offset * 1000f,
                    endX = offset * 1000f + 1000f
                ),
                shape = RoundedCornerShape(12.dp)
            )
    )
}

/**
 * Loading skeleton for conversation card.
 */
@Composable
fun ConversationCardSkeleton() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        ShimmerBox(modifier = Modifier.height(24.dp).fillMaxWidth(0.7f))
        Spacer(modifier = Modifier.height(8.dp))
        ShimmerBox(modifier = Modifier.height(16.dp).fillMaxWidth(0.9f))
        Spacer(modifier = Modifier.height(4.dp))
        ShimmerBox(modifier = Modifier.height(12.dp).fillMaxWidth(0.3f))
    }
}
