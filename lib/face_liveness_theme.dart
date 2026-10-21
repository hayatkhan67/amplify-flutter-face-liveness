import 'package:flutter/material.dart';

/// Optional color overrides for the native camera UI's Material3 color
/// scheme. Any field left `null` keeps the native view's own default
/// (currently AWS's stock orange theme on Android). Pass a [FaceLivenessTheme]
/// to [FaceLivenessDetector] to brand the camera screen without forking the
/// plugin.
///
/// Currently applied on Android only — the iOS native view does not yet
/// read these values.
class FaceLivenessTheme {
  const FaceLivenessTheme({
    this.primaryColor,
    this.onPrimaryColor,
    this.backgroundColor,
    this.onBackgroundColor,
    this.surfaceColor,
    this.onSurfaceColor,
    this.errorColor,
    this.onErrorColor,
    this.errorContainerColor,
    this.onErrorContainerColor,
  });

  /// The accent color for primary actions (e.g. the "Start video check" button).
  final Color? primaryColor;

  /// Content color drawn on top of [primaryColor].
  final Color? onPrimaryColor;

  /// The screen's background color.
  final Color? backgroundColor;

  /// Content color drawn on top of [backgroundColor] (titles, body text).
  final Color? onBackgroundColor;

  /// The color of raised surfaces (e.g. cards, sheets).
  final Color? surfaceColor;

  /// Content color drawn on top of [surfaceColor].
  final Color? onSurfaceColor;

  /// The color used for error states.
  final Color? errorColor;

  /// Content color drawn on top of [errorColor].
  final Color? onErrorColor;

  /// The background color of error containers/banners.
  final Color? errorContainerColor;

  /// Content color drawn on top of [errorContainerColor].
  final Color? onErrorContainerColor;

  /// Serializes the set overrides as ARGB32 ints for the platform channel.
  /// Unset fields are omitted entirely so the native side can fall back to
  /// its own defaults for just those values.
  Map<String, int> toCreationParams() => {
    if (primaryColor != null) 'primaryColor': primaryColor!.toARGB32(),
    if (onPrimaryColor != null) 'onPrimaryColor': onPrimaryColor!.toARGB32(),
    if (backgroundColor != null) 'backgroundColor': backgroundColor!.toARGB32(),
    if (onBackgroundColor != null)
      'onBackgroundColor': onBackgroundColor!.toARGB32(),
    if (surfaceColor != null) 'surfaceColor': surfaceColor!.toARGB32(),
    if (onSurfaceColor != null) 'onSurfaceColor': onSurfaceColor!.toARGB32(),
    if (errorColor != null) 'errorColor': errorColor!.toARGB32(),
    if (onErrorColor != null) 'onErrorColor': onErrorColor!.toARGB32(),
    if (errorContainerColor != null)
      'errorContainerColor': errorContainerColor!.toARGB32(),
    if (onErrorContainerColor != null)
      'onErrorContainerColor': onErrorContainerColor!.toARGB32(),
  };
}
