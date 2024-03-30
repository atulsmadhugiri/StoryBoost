import Foundation

import AVFoundation
import CoreGraphics
import Foundation

enum VideoExportError: Error {
  case assetCreationFailed
  case trackCreationFailed
  case timeRangeInsertionFailed
  case exportSessionCreationFailed
  case exportFailed(Error?)
  case imageLoadingFailed
}

func overlayImageOnVideo(imagePath: String, videoURL: URL, outputURL: URL) async throws {
  // Load image using CoreGraphics
  guard let imageDataProvider = CGDataProvider(url: URL(fileURLWithPath: imagePath) as CFURL),
    let cgImage = CGImage(
      pngDataProviderSource: imageDataProvider, decode: nil, shouldInterpolate: true,
      intent: .defaultIntent)
  else {
    throw VideoExportError.imageLoadingFailed
  }

  let mixComposition = AVMutableComposition()

  let asset = AVAsset(url: videoURL)

  guard
    let videoTrack = mixComposition.addMutableTrack(
      withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)),
    let audioTrack = mixComposition.addMutableTrack(
      withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)),
    let assetVideoTrack = try await asset.loadTracks(withMediaType: .video).first,
    let assetAudioTrack = try await asset.loadTracks(withMediaType: .audio).first
  else {
    throw VideoExportError.trackCreationFailed
  }

  do {
    try await videoTrack.insertTimeRange(
      CMTimeRangeMake(start: .zero, duration: asset.load(.duration)), of: assetVideoTrack, at: .zero)
    try await audioTrack.insertTimeRange(
      CMTimeRangeMake(start: .zero, duration: asset.load(.duration)), of: assetAudioTrack, at: .zero)
  } catch {
    throw VideoExportError.timeRangeInsertionFailed
  }

  let videoSize = try await assetVideoTrack.load(.naturalSize)
  let videoLayerFrame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
  let overlayLayerFrame = CGRect(
    x: 0, y: videoSize.height / 2, width: videoSize.width, height: videoSize.height / 2)

  let overlayLayer = CALayer()
  overlayLayer.contents = cgImage
  overlayLayer.contentsGravity = .resizeAspectFill
  overlayLayer.frame = overlayLayerFrame
  let rotation = CATransform3DMakeRotation(1.5 * .pi, 0, 0, 1)  // 90 degrees in radians
  overlayLayer.transform = rotation

  let videoLayer = CALayer()
  videoLayer.frame = videoLayerFrame

  let parentLayer = CALayer()
  parentLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
  parentLayer.addSublayer(videoLayer)
  parentLayer.addSublayer(overlayLayer)

  let videoComposition = AVMutableVideoComposition()
  videoComposition.renderSize = videoSize
  videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
  videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
    postProcessingAsVideoLayer: videoLayer, in: parentLayer)

  let instruction = AVMutableVideoCompositionInstruction()
  instruction.timeRange = try await CMTimeRangeMake(start: .zero, duration: asset.load(.duration))
  let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
  instruction.layerInstructions = [layerInstruction]
  videoComposition.instructions = [instruction]

  guard
    let exporter = AVAssetExportSession(
      asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
  else {
    throw VideoExportError.exportSessionCreationFailed
  }
  exporter.outputURL = outputURL
  exporter.outputFileType = .mp4
  exporter.shouldOptimizeForNetworkUse = true
  exporter.videoComposition = videoComposition

  try await withCheckedThrowingContinuation { continuation in
    exporter.exportAsynchronously {
      switch exporter.status {
      case .completed:
        continuation.resume()
      case .failed:
        continuation.resume(throwing: VideoExportError.exportFailed(exporter.error))
      default:
        continuation.resume(throwing: VideoExportError.exportFailed(nil))
      }
    }
  }
}
