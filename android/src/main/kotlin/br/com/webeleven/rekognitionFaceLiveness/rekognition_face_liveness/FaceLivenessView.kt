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
        // Lets TalkBack announce something meaningful for this region
        // instead of leaving it unlabeled; overridable from Dart via
        // `FaceLivenessDetector.semanticLabel`.
        composeView.contentDescription =
            creationParams?.get("semanticLabel") as? String ?: "Face verification camera"
    }

    /// Reads an optional ARGB32 color sent from Dart (`Color.toARGB32()`).
    /// The platform channel may deliver it as an Int or a Long depending on
    /// the value's magnitude, so this accepts any `Number`. Falls back to
    /// [default] when the key is absent, letting a host app override only
    /// the colors it cares about.
    private fun colorParam(creationParams: Map<String?, Any?>?, key: String, default: Color): Color {
        val raw = creationParams?.get(key) as? Number ?: return default
        return Color(raw.toLong().toInt())
    }

    init {
        try {
            // Default to the stock AWS orange theme; a host app overrides
            // any subset of these via `FaceLivenessTheme` on the Dart side.
            val colorScheme = lightColorScheme(
                primary = colorParam(creationParams, "primaryColor", Color(0xFFFFA500)),
                onPrimary = colorParam(creationParams, "onPrimaryColor", Color.White),
                background = colorParam(creationParams, "backgroundColor", Color.White),
                onBackground = colorParam(creationParams, "onBackgroundColor", Color(0xFF0D1926)),
                surface = colorParam(creationParams, "surfaceColor", Color.White),
                onSurface = colorParam(creationParams, "onSurfaceColor", Color(0xFF0D1926)),
                error = colorParam(creationParams, "errorColor", Color(0xFF950404)),
                onError = colorParam(creationParams, "onErrorColor", Color.White),
                errorContainer = colorParam(creationParams, "errorContainerColor", Color(0xFFB8CEF9)),
                onErrorContainer = colorParam(creationParams, "onErrorContainerColor", Color(0xFF002266))
            )

            // Set up the composable view
            composeView.setContent {
                MaterialTheme(colorScheme = colorScheme) {
                    // Get parameters from Flutter
                    val sessionId = creationParams?.get("sessionId") as? String ?: ""
                    val region = creationParams?.get("region") as? String ?: "us-east-1"
                    // Skip AWS's own instructions/photosensitivity-warning
                    // screen when the host app already showed its own
                    // equivalent — see `FaceLivenessDetector(disableStartView:)`
                    // on the Dart side.
                    val disableStartView = creationParams?.get("disableStartView") as? Boolean ?: false

                    Log.d(TAG, "Initializing FaceLivenessDetector with sessionId=$sessionId, region=$region, disableStartView=$disableStartView")

                    // Use default Amplify authentication and credentials provider
                    FaceLivenessDetector(
                        sessionId = sessionId,
                        region = region,
                        disableStartView = disableStartView,
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
