

import Foundation
import CoreImage.CIFilterBuiltins
import SDWebImage
import SwiftUI
import OSLog
import Alpacka
import Combine

private struct ResultsImage {
    var image: UIImage
}

private struct PackableObject: Sized, Hashable {
    var packingSize: Alpacka.Size {
        .init(CGSize(width: width, height: height))
    }
    var origin: CGPoint
    var image: UIImage
    var width: CGFloat
    var height: CGFloat
    let uid: String = UUID().uuidString
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(origin.x)
        hasher.combine(origin.y)
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(uid)
    }
}

public struct ImageLayouter {
    static var cancellables = Set<AnyCancellable>()
    
    private static  func createLayout(border: CGFloat, packedImages: [PackableObject], width: CGFloat, ratio: Double, counter: Int, completed: @escaping (ResultsImage?) -> Void) {
        // Logger().log("\(#function) \(#line)")
        let size = CGSize(width: width, height: width / ratio)
        Alpacka.pack(packedImages,
                     origin: \.origin,
                     in: .init(w: size.width, h: size.height))
        .sink { result in
            switch result {
            case let .overFlow(packed, overFlow: overFlow):
                // Logger().log("\(#function) \(#line)")
                
                var newImages = packed
                newImages.append(contentsOf: overFlow.map({ object in
                    var newObject = object
                    let percentage =  Double.random(in: 0.95...0.99)
                    newObject.width *= percentage
                    newObject.height *= percentage
                    return newObject
                }))
                if counter < 50 {
                    self.createLayout(border: border, packedImages: newImages, width: width, ratio: ratio, counter: counter + 1, completed: completed)
                } else {
                    self.convertLayout(border: border, images: packed, width: size.width, height: size.height) { image in
                        completed(image)
                    }
                }
            case let .packed(items):
                // Logger().log("\(#function) \(#line)")
                self.convertLayout(border: border, images: items, width: size.width, height: size.height) { image in
                    completed(image)
                }
            }
        }
        .store(in: &cancellables)
    }
    
    private static func convertLayout(border: CGFloat, images: [PackableObject], width: CGFloat, height: CGFloat, completed: @escaping (ResultsImage?) -> Void) {
        // Logger().log("\(#function) \(#line)")
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0.0)
        var newimages1 = [PackableObject]()
        var newimages = [PackableObject]()
        for item1 in images {
            var possibleDown = height - item1.height - item1.origin.y
            for item2 in images {
                if item1.hashValue != item2.hashValue {
                    if possibleDown > 0 {
                        let item1max = item1.origin.y + item1.height
                        let item2min = item2.origin.y
                        let a1 = item1.origin.x
                        let a2 = item1.origin.x + item1.width
                        let b1 = item2.origin.x
                        let b2 = item2.origin.x + item2.width
                        if item2.origin.y > item1.origin.y &&
                            ( max(a2, b2) - min(a1, b1) < (a2 - a1) + (b2 - b1)) {
                            if item2min > item1max {
                                possibleDown = min(item2min - item1max, possibleDown)
                            } else {
                                possibleDown = 0
                            }
                        }
                    }
                }
            }
            var newItem = item1
            newItem.height += possibleDown
            newimages1.append(newItem)
        }
        newimages.append(contentsOf: newimages1)
        // Logger().log("\(#function) \(#line)")
        for item1 in newimages1 {
            var possibleRight = width - item1.width - item1.origin.x
            for item2 in newimages1 {
                if item1.hashValue != item2.hashValue {
                    if possibleRight > 0 {
                        let item1max = item1.origin.x + item1.width
                        let item2min = item2.origin.x
                        let a1 = item1.origin.y
                        let a2 = item1.origin.y + item1.height
                        let b1 = item2.origin.y
                        let b2 = item2.origin.y + item2.height
                        if item2.origin.x > item1.origin.x &&
                            ( max(a2, b2) - min(a1, b1) < (a2 - a1) + (b2 - b1)) {
                            if item2min > item1max {
                                possibleRight = min(item2min - item1max, possibleRight)
                            } else {
                                possibleRight = 0
                            }
                        }
                    }
                }
            }
            var newItem = item1
      newItem.width += possibleRight
            newimages.append(newItem)
        }
        // Logger().log("\(#function) \(#line)")
        
        for item in newimages {
            let newSize = CGSize(width: item.width - border * 2, height: item.height - border * 2)
            let point = CGPoint(x: item.origin.x + border, y: item.origin.y + border)
            if let image = item.image.resizeAndScaleToFill(scaledToFill: newSize) {
                image.draw(in: CGRect(origin: point, size: newSize))
            }
        }
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let result = result {
            completed(ResultsImage(image: result))
        } else {
            completed(nil)
        }
        // Logger().log("\(#function) \(#line)")
        
    }
    
    public static func layout(border: CGFloat, images: [UIImage], ratio: Double, completed: @escaping (UIImage?) -> Void) {
        // Logger().log("\(#function) \(#line)")
        DispatchQueue.global(qos: .default).async {
            let packedImages = images.map { image in
                PackableObject(origin: .zero, image: image, width: image.size.width, height: image.size.height)
            }
            var surface: CGFloat = 0
            for item in images {
                surface += item.size.width * item.size.height
            }
            let width: CGFloat = sqrt(surface * ratio)
            // Logger().log("\(#function) \(#line)")
            createLayout(border: border, packedImages: packedImages, width: width, ratio: ratio, counter: 0) { resultsImage in
                if let resultsImage = resultsImage {
                    completed(resultsImage.image)
                } else {
                    completed(nil)
                }
            }
        }
    }
}
 


extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}


#if os(iOS)
extension UIImage {
    @objc public func resizeAndScaleToFill(scaledToFill size: CGSize) -> UIImage? {
        let scale: CGFloat = max(size.width / self.size.width, size.height / self.size.height)
        let width: CGFloat = self.size.width * scale
        let height: CGFloat = self.size.height  * scale
        let imageRect = CGRect(x: (size.width - width) / 2.0, y: (size.height - height) / 2.0, width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: imageRect)
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
#else
extension NSImage {
    @objc public func resizeAndScaleToFill(scaledToFill size: CGSize) -> NSImage? {
        return self.resizeWhileMaintainingAspectRatioToSize(size: size)
    }
}


extension NSImage {
    
    /// Returns the height of the current image.
    var height: CGFloat {
        return self.size.height
    }
    
    /// Returns the width of the current image.
    var width: CGFloat {
        return self.size.width
    }
    
    /// Returns a png representation of the current image.
    var PNGRepresentation: Data? {
        if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .png, properties: [:])
        }
        
        return nil
    }
    
    ///  Copies the current image and resizes it to the given size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func copy(size: NSSize) -> NSImage? {
        // Create a new rect with given width and height
        let frame = NSMakeRect(0, 0, size.width, size.height)
        
        // Get the best representation for the given size.
        guard let rep = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create an empty image with the given size.
        let img = NSImage(size: size)
        
        // Set the drawing context and make sure to remove the focus before returning.
        img.lockFocus()
        defer { img.unlockFocus() }
        
        // Draw the new image
        if rep.draw(in: frame) {
            return img
        }
        
        // Return nil in case something went wrong.
        return nil
    }
    
    ///  Copies the current image and resizes it to the size of the given NSSize, while
    ///  maintaining the aspect ratio of the original image.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func resizeWhileMaintainingAspectRatioToSize(size: NSSize) -> NSImage? {
        let newSize: NSSize
        
        let widthRatio  = size.width / self.width
        let heightRatio = size.height / self.height
        
        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.width * widthRatio), height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.width * heightRatio), height: floor(self.height * heightRatio))
        }
        
        return self.copy(size: newSize)
    }
    
    ///  Copies and crops an image to the supplied size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The cropped copy of the given image.
    func crop(size: NSSize) -> NSImage? {
        // Resize the current image, while preserving the aspect ratio.
        guard let resized = self.resizeWhileMaintainingAspectRatioToSize(size: size) else {
            return nil
        }
        // Get some points to center the cropping area.
        let x = floor((resized.width - size.width) / 2)
        let y = floor((resized.height - size.height) / 2)
        
        // Create the cropping frame.
        let frame = NSMakeRect(x, y, size.width, size.height)
        
        // Get the best representation of the image for the given cropping frame.
        guard let rep = resized.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create a new image with the new size
        let img = NSImage(size: size)
        
        img.lockFocus()
        defer { img.unlockFocus() }
        
        if rep.draw(in: NSMakeRect(0, 0, size.width, size.height),
                    from: frame,
                    operation: NSCompositingOperation.copy,
                    fraction: 1.0,
                    respectFlipped: false,
                    hints: [:]) {
            // Return the cropped image.
            return img
        }
        
        // Return nil in case anything fails.
        return nil
    }
    
    ///  Saves the PNG representation of the current image to the HD.
    ///
    /// - parameter url: The location url to which to write the png file.
    func savePNGRepresentationToURL(url: URL) throws {
        if let png = self.PNGRepresentation {
            try png.write(to: url, options: .atomicWrite)
        }
    }
}
#endif
