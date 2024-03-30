import AVKit
import SwiftUI

struct ContentView: View {
  @State private var player = AVPlayer()

  var body: some View {
    VStack {

      ZStack {
        VideoPlayer(player: player)
          .edgesIgnoringSafeArea(.all)
          .navigationBarBackButtonHidden()
          .onAppear {
            let url = URL(string: "https://blob.sh/output.mp4")

            if let url {
              player = AVPlayer(url: url)
              player.play()
            }

          }
          .onDisappear {
            player.pause()
          }.frame(width: 278, height: 600).cornerRadius(8)
        ProgressView().progressViewStyle(CircularProgressViewStyle())
        Color.gray.opacity(0.1).cornerRadius(8).frame(width: 360, height: 600).padding()
      }

    }

  }
}

#Preview {
  ContentView()
}
