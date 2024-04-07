import Foundation
import Photos

func potentiallyRequestAuthorization() async -> PHAuthorizationStatus {
  let existingStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
  if existingStatus != .notDetermined { return existingStatus }
  return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
}

enum VideoSaveError: Error {
  case notAuthorized
  case unknown
}

// Inspired by https://stackoverflow.com/a/76429751
func saveVideo(url: URL) async throws {
  let existingStatus = await potentiallyRequestAuthorization()
  if existingStatus != .authorized {
    throw VideoSaveError.notAuthorized
  }

  do {
    try await PHPhotoLibrary.shared().performChanges {
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
    }
  } catch {
    throw VideoSaveError.unknown
  }
}
