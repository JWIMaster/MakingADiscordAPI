import UIKit
import ImageIO
import MobileCoreServices

func png8Data(from image: UIImage) -> Data? {
    guard let cgImage = image.cgImage else { return nil }

    let width = cgImage.width
    let height = cgImage.height

    // RGBA bitmap context
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    guard let drawnImage = context.makeImage() else { return nil }

    // Save PNG (8-bit)
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data, kUTTypePNG, 1, nil) else { return nil }

    let properties: CFDictionary = [
        kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB,
        kCGImagePropertyDepth: 8
    ] as CFDictionary

    CGImageDestinationAddImage(destination, drawnImage, properties)
    guard CGImageDestinationFinalize(destination) else { return nil }

    return data as Data
}
