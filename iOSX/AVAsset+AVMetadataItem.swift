//
//  AVAsset+AVMetadataItem.swift
//  swiftlets
//
//  Created by Frank Vernon on 1/20/18.
//  Copyright © 2018 Frank Vernon. All rights reserved.
//

import Foundation
import MediaPlayer

// MARK: - Generaly useful utilities

public extension AVAsset {
    
    ///Returns first instance of an identifier in the metadata, if any.
    /// This is useful for the vast majority of idenitifiers where you expect only a single instance to appear in the metadata.
    func metadataItem(forIdentifier identifier: AVMetadataIdentifier) -> AVMetadataItem? {
        AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: identifier).first
    }
    
    ///Returns a mapping of identifiers to their values in the metadata, if any
    func metadataItems(forIdentifiers identifiers: [AVMetadataIdentifier]) -> [AVMetadataIdentifier: [AVMetadataItem]] {
        identifiers.reduce(into: [AVMetadataIdentifier: [AVMetadataItem]]()) { (result, identifier) in
            result[identifier] = AVMetadataItem.metadataItems(from: self.metadata, filteredByIdentifier: identifier)
        }
    }
}

// MARK: - AVMetadataKeySpace abstractions

public extension AVAsset {
    
    //Commonly accessed common identifiers
    var title: String? {
        metadataItem(forIdentifier: .commonIdentifierTitle)?.stringValue
    }
    
    var artist: String? {
        metadataItem(forIdentifier: .commonIdentifierArtist)?.stringValue
    }
    
    var album: String? {
        metadataItem(forIdentifier: .commonIdentifierAlbumName)?.stringValue
    }
    
    var artworkData: Data? {
        metadataItem(forIdentifier: .commonIdentifierArtwork)?.dataValue
    }
    
    //Commonly accessed un-common identifiers
    var comments: String? {
        let items = self.metadataItems(forIdentifiers: [.quickTimeUserDataComment,
                                                        .quickTimeMetadataComment,
                                                        .iTunesMetadataUserComment,
                                                        .id3MetadataComments,
                                                        .id3V2MetadataComments])
        
        return items.first(where: {!$1.isEmpty})?.value.first?.stringValue
    }
    
    ///Returns BPM for iTunes and id3 v2 and later
    var beatsPerMinute: Int? {
        let items = self.metadataItems(forIdentifiers: [.iTunesMetadataBeatsPerMin,
                                                        .id3MetadataBeatsPerMinute,
                                                        .id3V2MetadataBeatsPerMinute])
        
        return items.first(where: {!$1.isEmpty})?.value.first?.numberValue?.intValue
    }
    
    var grouping: String? {
        metadataItem(forIdentifier: .iTunesMetadataGrouping)?.stringValue
    }
    
    //Assume grouping may be CSV list, parse and return as array with whitespace trimmed
    var groups: [String] {
        guard let grouping = grouping else {
            return []
        }
        
        return grouping.components(separatedBy: ",")
            .map{$0.trimmingCharacters(in: CharacterSet.whitespaces)}
            .filter{!$0.isEmpty}
    }

    var playbackDuration: TimeInterval {
        return duration.seconds
    }    
}
