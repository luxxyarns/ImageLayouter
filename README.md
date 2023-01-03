# ImageLayouter
Tool to layout images in a rectangle using binary tree based bin packing and additional growth adjustment

Sample usage

``` swift

import SwiftUI
import ImageLayouter

struct ContentView: View {
    var imageNames = [   "w5", "w6", "w7", "w8", "w9", "w1", "w2", "w3","w4", ].shuffled()
    @State var resultingImage: UIImage?
    @State var ratio: Double = 1
    
    func reload() {
        ImageLayouter.layout(border: 10, images: self.imageNames.map({ name in
            if let image = UIImage(named: name) {
                return image
            } else {
                return UIImage()
            }
        }), ratio: self.ratio) { image in
            if let image = image {
                DispatchQueue.main.async {
                    self.resultingImage = image
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { reader in
            VStack {
                ZStack {
                    if let image = resultingImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                        
                    } else {
                        Text("processing ...")
                            .onAppear() {
                                self.ratio = reader.size.width / reader.size.height
                                self.reload()
                            }
                    }
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                self.reload()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { newValue in
                    let w = reader.size.width
                    let h = reader.size.height
                    if UIDevice.current.orientation.isLandscape {
                        ratio = w > h ? w / h : h / w
                    }
                    if UIDevice.current.orientation.isPortrait {
                        ratio = w < h ? w / h : h / w
                    }
                    self.reload()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

```