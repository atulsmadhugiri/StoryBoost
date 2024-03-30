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
