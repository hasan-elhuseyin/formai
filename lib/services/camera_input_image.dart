import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

const Map<DeviceOrientation, int> _orientations = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

ImageFormatGroup cameraImageFormatGroup() {
  if (Platform.isAndroid) {
    return ImageFormatGroup.nv21;
  }
  return ImageFormatGroup.bgra8888;
}

InputImage? inputImageFromCameraImage({
  required CameraImage image,
  required CameraDescription camera,
  required CameraController controller,
}) {
  final sensorOrientation = camera.sensorOrientation;
  InputImageRotation? rotation;
  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  } else if (Platform.isAndroid) {
    var rotationCompensation =
        _orientations[controller.value.deviceOrientation];
    if (rotationCompensation == null) {
      return null;
    }
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
  } else {
    rotation = InputImageRotation.rotation0deg;
  }
  if (rotation == null) {
    return null;
  }

  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) {
    return null;
  }
  if (Platform.isAndroid && format != InputImageFormat.nv21) {
    return null;
  }
  if (Platform.isIOS && format != InputImageFormat.bgra8888) {
    return null;
  }
  if ((Platform.isAndroid || Platform.isIOS) && image.planes.length != 1) {
    return null;
  }

  final plane = image.planes.first;
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}
