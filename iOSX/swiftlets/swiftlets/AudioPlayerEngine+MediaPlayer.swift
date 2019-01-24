//
//  AudioPlayerEngine+MediaPlayer.swift
//  swiftlets
//
//  Created by Frank Vernon on 1/7/18.
//  Copyright © 2018 Frank Vernon. All rights reserved.
//

import Foundation
import MediaPlayer

public extension AudioPlayerEngine {
    @discardableResult func setTrack(mediaItem: MPMediaItem) -> Bool {
        guard let url: URL = mediaItem.assetURL else {
            return false
        }
        
        return setTrack(url: url)
    }
}
