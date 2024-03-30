import AVKit
import PhotosUI
import SwiftUI

struct TransferableImageSelection: Transferable {
  let image: Data

  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(importedContentType: .image) { data in
      if let jpegData = UIImage(data: data)?.jpegData(compressionQuality: 0.75) {
        return TransferableImageSelection(image: jpegData)
      } else {
        return TransferableImageSelection(image: data)
      }
    }
  }
}

struct ContentView: View {
  @State private var player = AVPlayer()
  @State private var selectedMediaData: Data?
  @State private var imageSelection: PhotosPickerItem?

  var body: some View {
    VStack {
      if let selectedMediaData {
        if let uiImage = UIImage(data: selectedMediaData) {
          Image(uiImage: uiImage)
            .resizable()
            .cornerRadius(8)
            .padding()
            .scaledToFit()
        }
      } else {
        Color.gray
          .opacity(0.1)
          .cornerRadius(8)
          .frame(width: 360, height: 360)
          .padding()
      }

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

        Button {
        } label: {
          HStack {
            Image(systemName: "sparkles").frame(height: 20)
            Text("Pimp my story")
          }.frame(maxWidth: .infinity)
        }.buttonStyle(.bordered).tint(.orange)

      }.padding()

    }.onChange(of: imageSelection) {
      if let imageSelection {
        imageSelection.loadTransferable(type: TransferableImageSelection.self) { result in
          switch result {
          case .success(let img?):
            self.selectedMediaData = img.image
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
