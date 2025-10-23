import UIKit
import FoundationCompatKit
import SwiftcordLegacy

final class AvatarCache {
    static let shared = AvatarCache()

    private let memoryCache = NSCache<NSString, UIImage>()

    private let cacheQueue = DispatchQueue(label: "avatar.cache.queue")

    private let cacheDirectory: String = {
        let dirs = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        return dirs.first ?? NSTemporaryDirectory()
    }()

    func avatar(for user: User, completion: @escaping (UIImage?) -> Void) {
        guard let id = user.id?.rawValue else {
            completion(nil)
            return
        }

        let avatarHash = user.avatarString ?? "default"
        let cacheKey = "\(id)-\(avatarHash)" as NSString
        let filePath = cacheDirectory + "/" + (cacheKey as String) + ".png"

        if let cached = memoryCache.object(forKey: cacheKey) {
            completion(cached)
            return
        }

        if let diskData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
           let image = UIImage(data: diskData) {
            memoryCache.setObject(image, forKey: cacheKey)
            completion(image)
            return
        }

        // No avatar? Return nil
        guard let avatarHash = user.avatarString else {
            completion(nil)
            return
        }

        // Download from Discord CDN
        let url = URL(string: "https://cdn.discordapp.com/avatars/\(id)/\(avatarHash).png?size=128")!
        URLSessionCompat.shared.dataTask(with: URLRequest(url: url)) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }

            // Make circular
            let circularImage = self.makeCircular(image: image)

            // Cache in memory and disk
            self.cacheQueue.async {
                self.memoryCache.setObject(circularImage, forKey: cacheKey)
                if let pngData = circularImage.pngData() {
                    try? pngData.write(to: URL(fileURLWithPath: filePath), options: .atomic)
                }
            }

            completion(circularImage)
        }.resume()
    }

    // MARK: - Helpers

    private func makeCircular(image: UIImage) -> UIImage {
        let diameter = min(image.size.width, image.size.height)
        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)

        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        let path = UIBezierPath(ovalIn: rect)
        path.addClip()
        image.draw(in: rect)
        let circularImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return circularImage ?? image
    }
    
    public func clearCache() {
        cacheQueue.async {
            self.memoryCache.removeAllObjects()
            
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(atPath: self.cacheDirectory) {
                for file in files {
                    if file.hasSuffix(".png") {
                        let filePath = self.cacheDirectory + "/" + file
                        try? fileManager.removeItem(atPath: filePath)
                    }
                }
            }
        }
    }
}
