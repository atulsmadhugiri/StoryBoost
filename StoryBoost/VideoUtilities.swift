import Foundation
import Photos

func potentiallyRequestAuthorization() async -> PHAuthorizationStatus {
  let existingStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
  if existingStatus != .notDetermined { return existingStatus }
  return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
}
