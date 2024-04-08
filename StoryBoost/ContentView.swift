import AVKit
import PhotosUI
import SwiftUI

struct TransferableImageSelection: Transferable {
  let image: Data

  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(importedContentType: .image) { data in
      if let pngData = UIImage(data: data)?.pngData() {
        return TransferableImageSelection(image: pngData)
      } else {
        return TransferableImageSelection(image: data)
      }
    }
  }
}

struct ContentView: View {
  @State private var player = AVQueuePlayer()
  @State private var playerLooper: AVPlayerLooper? = nil
  @State private var selectedMediaData: Data?
  @State private var imageSelection: PhotosPickerItem?
  @State private var videoURL: URL?
  @State private var pimpingInProgress: Bool = false

  var body: some View {
    VStack {

      if let videoURL {
        ZStack {
          VideoPlayer(player: player)
            .edgesIgnoringSafeArea(.all)
            .navigationBarBackButtonHidden()
            .onAppear {
              let playerItem = AVPlayerItem(url: videoURL)
              player = AVQueuePlayer(playerItem: playerItem)
              playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
              player.play()
            }
            .onDisappear {
              player.pause()
            }.frame(width: 278, height: 600).cornerRadius(8)
        }
      } else {
        if let selectedMediaData {
          if let uiImage = UIImage(data: selectedMediaData) {
            Image(uiImage: uiImage)
              .resizable()
              .cornerRadius(8)
              .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
              .scaledToFit()
          }
        } else {
          Color.gray
            .opacity(0.2)
            .cornerRadius(8)
            .frame(width: 360, height: 360)
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }

      }

      if let videoURL {
        HStack {
          Button {
            Task {
              try await saveVideo(url: videoURL)
            }
          } label: {
            HStack {
              Image(systemName: "arrow.down.square.fill").frame(height: 20)
              Text("Save")
            }.frame(maxWidth: .infinity)
          }.buttonStyle(.bordered).tint(.green)

          Button {
          } label: {
            HStack {
              ShareLink(item: videoURL) {
                Image(systemName: "square.and.arrow.up").frame(height: 20)
                Text("Share")
              }.frame(maxWidth: .infinity)
            }
          }.buttonStyle(.bordered).tint(.gray)

        }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
      }

      Divider()

      HStack {
        PhotosPicker(
          selection: $imageSelection, matching: .all(of: [.images, .not(.livePhotos)]),
          photoLibrary: .shared()
        ) {
          Button {
          } label: {
            HStack {
              Image(systemName: "photo").frame(height: 20)
              Text("Select image")
            }.frame(maxWidth: .infinity)
          }.buttonStyle(.bordered)
            .tint(.blue)
            .allowsHitTesting(false)
        }

        if let selectedMediaData {
          Button {
            self.pimpingInProgress = true
            Task {
              let destination = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")

              let mediaPath = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString).appendingPathExtension("png")

              do {
                try selectedMediaData.write(to: mediaPath)
                try await overlayImageOnVideo(imagePath: mediaPath, outputURL: destination)
                self.pimpingInProgress = false
                self.videoURL = destination
              } catch {
                print(error)
              }
            }
          } label: {
            HStack {
              Image(systemName: "sparkles")
                .symbolEffect(.pulse, isActive: self.pimpingInProgress)
                .frame(height: 20)
              Text(self.pimpingInProgress ? "Pimping..." : "Pimp my story")
            }.frame(maxWidth: .infinity)
          }.buttonStyle(.bordered).tint(.orange)
        }

      }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

    }.onChange(of: imageSelection) {
      if let imageSelection {
        imageSelection.loadTransferable(type: TransferableImageSelection.self) { result in
          switch result {
          case .success(let img?):
            self.selectedMediaData = img.image
            self.videoURL = nil
            print("Image selected successfully!")
          case .success(.none):
            print("No image selected.")
          case .failure(_):
            print("Image selection failed.")
          }
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
