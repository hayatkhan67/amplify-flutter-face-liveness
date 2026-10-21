package br.com.webeleven.rekognitionFaceLiveness.rekognition_face_liveness

import android.content.Context
import android.view.View
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import com.amplifyframework.ui.liveness.model.FaceLivenessDetectionException
import com.amplifyframework.ui.liveness.ui.FaceLivenessDetector
import io.flutter.plugin.platform.PlatformView
import android.util.Log

internal class FaceLivenessView(context: Context, id: Int, creationParams: Map<String?, Any?>?, val handler: EventStreamHandler) : PlatformView {
    private val composeView: ComposeView = ComposeView(context)
    private val TAG = "FaceLivenessView"

    override fun getView(): View {
        return composeView
    }

    override fun dispose() {}

    init {
        try {
            // Set up the composable view
            composeView.setContent {
                MaterialTheme(
                    // Connect Me brand palette (connect-me-mobileapp's
                    // AppColors.primary/primaryDark/black) instead of the
                    // plugin's default AWS orange theme.
                    colorScheme = lightColorScheme(
                        primary = Color(0xFFF03D3D),
                        onPrimary = Color.White,
                        background = Color.White,
                        onBackground = Color(0xFF0B0707),
                        surface = Color.White,
                        onSurface = Color(0xFF0B0707),
                        error = Color(0xFFB3282A),
                        onError = Color.White,
                        errorContainer = Color(0xFFF9D6D6),
                        onErrorContainer = Color(0xFFB3282A)
                    )
                ) {
                    // Get parameters from Flutter
                    val sessionId = creationParams?.get("sessionId") as? String ?: ""
                    val region = creationParams?.get("region") as? String ?: "us-east-1"
                    
                    Log.d(TAG, "Initializing FaceLivenessDetector with sessionId=$sessionId, region=$region")
                    
                    // Use default Amplify authentication and credentials provider
                    FaceLivenessDetector(
                        sessionId = sessionId,
                        region = region,
                        onComplete = {
                            Log.d(TAG, "FaceLivenessDetector completed successfully")
                            handler.onComplete()
                        },
                        onError = { error ->
                            Log.e(TAG, "FaceLivenessDetector error: ${error.javaClass.simpleName}: ${error.message}")
                            
                            when (error) {
                                is FaceLivenessDetectionException.SessionNotFoundException -> {
                                    handler.onError("sessionNotFound")
                                }
                                is FaceLivenessDetectionException.AccessDeniedException -> {
                                    handler.onError("accessDenied")
                                }
                                is FaceLivenessDetectionException.CameraPermissionDeniedException -> {
                                    handler.onError("cameraPermissionDenied")
                                }
                                is FaceLivenessDetectionException.SessionTimedOutException -> {
                                    handler.onError("sessionTimedOut")
                                }
                                is FaceLivenessDetectionException.UserCancelledException -> {
                                    handler.onError("userCancelled")
                                }
                                else -> {
                                    handler.onError("error")
                                }
                            }
                        }
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing FaceLivenessDetector", e)
            handler.onError("initialization_error")
            
            // Create empty view
            composeView.setContent {
                MaterialTheme {
                    // Empty view
                }
            }
        }
    }
}
