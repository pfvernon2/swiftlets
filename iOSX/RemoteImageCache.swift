//
//  RemoteImageCache.swift
//  swiftlets
//
//  Created by Frank Vernon on 10/30/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

fileprivate let defaultDiskCacheSize:Int = 200 * 1024 * 1024 //200 MiB
fileprivate let defaultMemoryCacheSize:Int = 100 * 1024 * 1024 //100 MiB
fileprivate let defaultCacheName:String = "RemoteImageCache"

/**
 Class that manages both an on-disk and in-memory cache of images retrieved from URLs. Caches are limited in size and can be configured.
 
 - Parameter memoryCapacity: Maximum size in bytes of images to keep in memory.
 - Parameter diskCapacity: Maximum size in bytes of images data to keep on disk.
 - Parameter cacheName: Name of the on-disk cache.
 
 - Note: This object is thread safe but you may encounter race conditions when updating the caches across multiple threads.
 
 - Note: Each instance of this class manages its own in-memory cache. However, to maintain seperate on-disk caches you must give them unique names.

 - Returns: Image, or nil in completion.
*/
open class RemoteImageCache {
    public var session:URLSession
    fileprivate var memoryCache = NSCache<NSString, UIImage>()
    
    init(memoryCapacity:Int = defaultMemoryCacheSize, diskCapacity:Int = defaultDiskCacheSize, cacheName:String = defaultCacheName) {
        let sessionCache:URLCache = URLCache(memoryCapacity: 0, diskCapacity: diskCapacity, diskPath:defaultCacheName)
        let sessionConfiguration:URLSessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.urlCache = sessionCache
        self.session = URLSession(configuration: sessionConfiguration)
        
        memoryCache.totalCostLimit = memoryCapacity
    }
    
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

