//
//  RemoteImageCache.swift
//  swiftlets
//
//  Created by Frank Vernon on 10/30/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

let kImageCacheOnDiskSize:Int = 200 * 1024 * 1024 //200 MiB
let kImageCacheInMemorySize:Int = 100 * 1024 * 1024 //100 MiB

/**
 Class that manages both an on-disk and in-memory cache of images retrieved from URLs. Caches are limited in size and can be configured.
 
 - Parameter memoryCapacity: Maximum size in bytes of images to keep in memory.
 - Parameter diskCapacity: Maximum size in bytes of image data to keep on disk.
 - Parameter cacheName: Optional name of the on-disk cache.
 
 - Note: This object is thread safe but you may encounter race conditions when updating the caches across multiple threads.
 
 - Note: Each instance of this class manages its own in-memory cache. However, to maintain seperate on-disk caches you must give them unique cache names.
 */
open class RemoteImageCache {
    public var session:URLSession
    fileprivate var memoryCache = NSCache<NSString, UIImage>()
    
    init(memoryCapacity:Int = kImageCacheInMemorySize, diskCapacity:Int = kImageCacheOnDiskSize, cacheName:String?) {
        let sessionCache:URLCache = URLCache(memoryCapacity: 0, diskCapacity: diskCapacity, diskPath:cacheName)
        let sessionConfiguration:URLSessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.urlCache = sessionCache
        self.session = URLSession(configuration: sessionConfiguration)
        
        memoryCache.totalCostLimit = memoryCapacity
    }
    
    ///Clear the in-memory cache while maintaining the on-disk cache.
    /// This is handy for freeing memory when app notified of memory pressure
    func clearInMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    ///Flush both on-disk and in-memory caches
    func flushCache() {
        self.session.configuration.urlCache?.removeAllCachedResponses()
        memoryCache.removeAllObjects()
    }
    
    ///Retrieve image from local cache or from URL.
    /// - Parameter fromURL: URL of the image resource.
    /// - Parameter closure: closure called on success or failure.
    /// - Returns: UIImage or nil if an error occurs.
    func cachedImage(fromURL url:URL, closure:@escaping (_ image:UIImage?) ->()) {
        let imageKey:NSString = url.absoluteString as NSString
        
        DispatchQueue.global().async {
            //check memory first
            if let image:UIImage = self.memoryCache.object(forKey: imageKey) {
                closure(image)
                return
            }
            
            //retrieve from disk cache/URL location
            let downloadTask:URLSessionDataTask = self.session.dataTask(with: url) { data,response,error in
                guard let data = data, let image:UIImage = UIImage(data: data), error == nil else {
                    closure(nil)
                    return
                }
                
                //add image to memory cache (along with cost)
                self.memoryCache.setObject(image, forKey: imageKey, cost:data.count)
                
                closure(image)
            }
            
            downloadTask.resume()
        }
    }
}

