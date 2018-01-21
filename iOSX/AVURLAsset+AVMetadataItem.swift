//
//  AVURLAsset+AVMetadataItem.swift
//  swiftlets
//
//  Created by Frank Vernon on 1/20/18.
//  Copyright © 2018 Frank Vernon. All rights reserved.
//

import Foundation
import MediaPlayer

// MARK: - Generaly useful utilities

public extension AVURLAsset {
    
    ///Returns first instance of an identifier in the metadata, if any.
    /// This is useful for the vast majority of idenitifiers where you expect only a single instance to appear in the metadata.
    public func metadataItem(forIdentifier identifier:AVMetadataIdentifier) -> AVMetadataItem? {
        return AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: identifier).first
    }

    ///Returns a mapping of identifiers to their values in the metadata, if any
    public func metadataItems(forIdentifiers identifiers:[AVMetadataIdentifier]) -> [AVMetadataIdentifier: [AVMetadataItem]] {
        return identifiers.reduce(into: [AVMetadataIdentifier: [AVMetadataItem]]()) { (result, identifier) in
            result[identifier] = AVMetadataItem.metadataItems(from: self.metadata, filteredByIdentifier: identifier)
        }
    }
}

// MARK: - AVMetadataKeySpace abstractions

public extension AVURLAsset {

    //Commonly accessed common identifiers
    public var title: String? {
        return metadataItem(forIdentifier: .commonIdentifierTitle)?.stringValue
    }
    
    public var artist: String? {
        return metadataItem(forIdentifier: .commonIdentifierArtist)?.stringValue
    }
    
    public var album: String? {
        return metadataItem(forIdentifier: .commonIdentifierAlbumName)?.stringValue
    }
    
    public var artworkData: Data? {
        return metadataItem(forIdentifier: .commonIdentifierArtwork)?.dataValue
    }
    
    //Commonly accessed un-common identifiers
    public var comment: String? {
        let items = self.metadataItems(forIdentifiers: [.quickTimeUserDataComment,
                                                        .quickTimeMetadataComment,
                                                        .iTunesMetadataUserComment,
                                                        .id3MetadataComments,
                                                        .id3V2MetadataComments])
        
        return items.first(where: {!$1.isEmpty})?.value.first?.stringValue
    }

    ///Returns BPM for iTunes and id3 v2 and later
    public var beatsPerMinute: Int? {
        let items = self.metadataItems(forIdentifiers: [.iTunesMetadataBeatsPerMin,
                                                        .id3MetadataBeatsPerMinute,
                                                        .id3V2MetadataBeatsPerMinute])
        
        return items.first(where: {!$1.isEmpty})?.value.first?.numberValue?.intValue
    }
}
