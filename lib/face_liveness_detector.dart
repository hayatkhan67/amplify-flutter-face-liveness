import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'face_liveness_theme.dart';

export 'face_liveness_theme.dart';

/// A Flutter widget that provides AWS Rekognition Face Liveness detection functionality.
///
/// This widget requires a valid AWS Rekognition Face Liveness session ID and region.
/// It uses native platform views to integrate with the AWS Amplify Face Liveness SDK.
class FaceLivenessDetector extends StatefulWidget {
  /// The AWS Rekognition Face Liveness session ID obtained from your backend.
  final String sessionId;

  /// The AWS region where the Face Liveness session was created.
  final String region;

  /// Callback that is called when face liveness check is completed successfully.
  final VoidCallback? onComplete;

  /// Callback that is called when an error occurs during face liveness check.
  /// The error code is passed as a parameter.
  final ValueChanged<String>? onError;

  /// Optional color overrides for the native camera screen, so the host app
  /// can brand it without forking this plugin. See [FaceLivenessTheme].
  /// Applied on Android via a Material3 `ColorScheme`. On iOS, Amplify's
  /// `FaceLivenessDetectorView` has no official color API, so only
  /// [FaceLivenessTheme.primaryColor] is applied there, as a best-effort
  /// `.tint()` — the color-cycling liveness challenge itself is never
  /// themeable on either platform, by AWS design (it's a security signal,
  /// not decoration).
  final FaceLivenessTheme? theme;

  /// Accessibility label announced by screen readers (TalkBack/VoiceOver)
  /// for this view. Defaults to a generic description if omitted.
  final String? semanticLabel;

  /// Skips AWS's own instructions/photosensitivity-warning start screen —
  /// use this when your app already shows an equivalent explainer before
  /// mounting this widget. Supported on both Android and iOS. The actual
  /// liveness capture (oval framing, color-cycling challenge) that follows
  /// is unaffected either way — AWS doesn't expose that for customization.
  final bool disableStartView;

  /// Creates a Face Liveness detector widget.
  ///
  /// [sessionId] is required and must be a valid AWS Rekognition Face Liveness session ID.
  /// [region] is required and must be a valid AWS region where the session was created.
  /// [onComplete] is called when the face liveness check is completed successfully.
  /// [onError] is called when an error occurs during the face liveness check.
  /// [theme] optionally overrides the native camera screen's colors.
  /// [semanticLabel] optionally overrides the screen-reader label.
  /// [disableStartView] skips AWS's own instructions screen.
  const FaceLivenessDetector({
    super.key,
    required this.sessionId,
    required this.region,
    this.onComplete,
    this.onError,
    this.theme,
    this.semanticLabel,
    this.disableStartView = false,
  });

  @override
  State<FaceLivenessDetector> createState() => _FaceLivenessDetectorState();
}

class _FaceLivenessDetectorState extends State<FaceLivenessDetector> {
  final _eventChannel = EventChannel('face_liveness_event');

  @override
  void initState() {
    super.initState();
    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event == 'complete') {
        widget.onComplete?.call();
      } else {
        widget.onError?.call(event);
      }
    });
  }

  Map<String, dynamic> _buildCreationParams() => {
    'sessionId': widget.sessionId,
    'region': widget.region,
    'disableStartView': widget.disableStartView,
    if (widget.semanticLabel != null) 'semanticLabel': widget.semanticLabel,
    ...?widget.theme?.toCreationParams(),
  };

  @override
  Widget build(BuildContext context) {
    final platformView = Platform.isIOS
        ? UiKitView(
            viewType: 'face_liveness_view',
            layoutDirection: TextDirection.ltr,
            creationParams: _buildCreationParams(),
            creationParamsCodec: const StandardMessageCodec(),
          )
        : AndroidView(
            viewType: 'face_liveness_view',
            layoutDirection: TextDirection.ltr,
            creationParams: _buildCreationParams(),
            creationParamsCodec: const StandardMessageCodec(),
          );

    // The platform view hosts native UI Flutter can't introspect, so give
    // assistive technologies an explicit label instead of leaving this
    // region unlabeled.
    return Semantics(
      container: true,
      label: widget.semanticLabel ?? 'Face verification camera',
      child: platformView,
    );
  }
}
