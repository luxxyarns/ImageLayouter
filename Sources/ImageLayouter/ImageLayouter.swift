

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
            for item2 in images {
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
            item.image.draw(in: CGRect(origin: point, size: newSize))
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
 
