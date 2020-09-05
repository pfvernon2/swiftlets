//
//  MPMediaItem+Util.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/25/20.
//  Copyright © 2020 Frank Vernon. All rights reserved.
//

import Foundation
import MediaPlayer
import MobileCoreServices
import CryptoKit

extension AVFileType {
    /// Reference file extension for UTI string
    var fileExtension: String? {
        guard let tag = UTTypeCopyPreferredTagWithClass(self as CFString, kUTTagClassFilenameExtension) else {
            return nil
        }
        
        return tag.takeRetainedValue() as String
    }
}

extension String {
    func sha256() -> String {
        guard let data:Data = self.data(using: String.Encoding.utf8) else {
            return String()
        }
        
        let hash = SHA256.hash(data: data)
        
        //return hex representation of the bytes without the description prefix
        //Note: This is significantly faster than doing String(format:) on the hash bytes
        return String(hash.description.suffix(64))
    }
}

extension MPMediaItem {
    /**
     Generate a hash value likely to define a media item uniquely which is unlikley to change unless the
     track and/or its metadata changes significantly.
     
     In my ananlysis, tracklength (in milliseconds) was highly unique but not 100% reliable. Track name,
     artist, and album are also added to the resulting hash to increase uniqueness.
     
     Rationale: Track name, artist and album, are likely to change only rarely and most likely
     to change only slightly such as correcting a typo in capitalization or white space. Thus the effort
     to remove whitespace and standardize the case.
    
    - Returns: A string representation of a hash of the track metadata.
     
    - note: Most of the performance hit here is accessing the MPMediaItem values, especially on initial access.
    */
    public func mediaItemHash() -> String {
        let title:String = normalizeString(self.title)
        let artist:String = normalizeString(self.artist)
        let album:String = normalizeString(self.albumTitle)
        let trackLength:String = String(self.playbackDuration)

        //Hash Title|Artist|Album|TrackLength with record seperators to ensure uniqueness of fields
        let hashString = [title, artist, album, trackLength].joined(separator: "\u{1c}")
        return hashString.sha256()
    }
    
    //Convert to lowercase, remove diacriticals, and strip all whitespace
    fileprivate func normalizeString(_ identifier:String?) -> String {
        guard let identifier = identifier else {
            return String()
        }
        
        let folded = identifier.folding(options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive], locale: nil)
        return String(folded.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
    }
}

extension MPMediaItem {
    //Assume grouping may be CSV list, parse and return as array with whitespace trimmed
    public var userGroups: [String] {
        userGrouping?.components(separatedBy: ",")
            .map{$0.trimmingCharacters(in: CharacterSet.whitespaces)}
            .filter{!$0.isEmpty} ?? []
    }
    
    public var isAVURLAsset: Bool {
        assetURL != nil
    }
}

public extension MPMediaItem {
    enum MatchingField {
        case title
        case artist
        case comments
        case lyrics(String)
    }
    
    ///Returns boolean indicating string match of at least one field of the media item along
    /// with an array of the fields that matched. In the case of the lyrics the first line of the lyrics
    /// containing a match is included.
    func hasMatch(for filter: String) -> (Bool, [MatchingField]) {
        guard filter.isNotEmpty else {
            return (false, [])
        }
        
        var result: [MatchingField] = []
        if let title = title, title.localizedCaseInsensitiveContains(filter) {
            result.append(.title)
        }
        
        if let artist = artist, artist.localizedCaseInsensitiveContains(filter) {
            result.append(.artist)
        }
        
        if let comments = comments, comments.localizedCaseInsensitiveContains(filter) {
            result.append(.comments)
        }
        
        if let lyrics = lyrics, let line = lyrics.lines.first(where: {$0.localizedCaseInsensitiveContains(filter)}) {
            result.append(.lyrics(line))
        }

        return (!result.isEmpty, result)
    }
}

public extension MPMediaItem {
    private func fileName() -> String {
        switch (title, artist) {
        case (.some, .some):
            return "\(title!) - \(artist!)"
            
        case (.some, .none):
            return title!
            
        case (.none, .some):
            return artist!
            
        default:
            return UUID().uuidString
        }
    }
        
    ///Export MPMediaItem to specified directory. On completion url of new file is set if successfully exported.
    /// - note: The combination of iTunes, MPMediaLibrary, iTunes Match, etc. results in inconsistent inclusion of
    ///         metadata being written to the files. This makes an attempt to pull minimal metadata from the MPMediaItem for
    ///         inclusion in the metadata written to the exported files but this may (will) result in imperfect preservation
    ///         of metadata in many cases.
    func exportFromMediaLibrary(to destinationDir: URL, completion: @escaping (URL?)->Swift.Void = { url in }) {
        guard let assetURL = assetURL else {
            completion(nil)
            return
        }
        
        let asset = AVURLAsset(url: assetURL,
                               options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        guard let exporter = AVAssetExportSession(asset: asset,
                                                  presetName: AVAssetExportPresetAppleM4A) else
        {
            completion(nil)
            return
        }
        exporter.shouldOptimizeForNetworkUse = false;
        exporter.outputFileType = AVFileType.m4a
        
        let destinationURL = FileManager.default.uniqueURL(in: destinationDir,
                                                           name: fileName(),
                                                           type: AVFileType.m4a.fileExtension ?? ".m4a")
        exporter.outputURL = destinationURL
        
        //It appears sometimes the media library does not write metadata into files.
        // This copies minimal metadata to the exporter if necessary.
        //I'm using title as proxy for missing metadata as it is uncommon to find a
        // MediaLibrary track without a title in metadata
        if asset.title == nil {
            var metadata = minimalMetaData()
            if let exportMetadata = exporter.metadata {
                metadata.append(contentsOf: exportMetadata)
            }
            exporter.metadata = metadata
        }
        
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                guard exporter.error == nil, let outputURL = exporter.outputURL else {
                    completion(nil)
                    return
                }
                completion(outputURL)
            }
        }
    }
    
    //A cherry-picked set of commonly available metadata elements along with things
    // the user may have added (and thus likely wants to keep.)
    fileprivate func minimalMetaData() -> [AVMetadataItem] {
        var result: [AVMetadataItem] = []
        
        func addItemToResult(id: AVMetadataIdentifier, space: AVMetadataKeySpace, value: (NSCopying & NSObjectProtocol)?) {
            guard let value = value else {
                return
            }
            let item = AVMutableMetadataItem()
            item.locale = NSLocale.current
            item.keySpace = space
            item.identifier = id
            item.value = value
            
            result.append(item)
        }
        
        //Common
        if let title = title, title.isNotEmpty {
            addItemToResult(id: .commonIdentifierTitle, space: .common, value: title as NSCopying & NSObjectProtocol)
        }

        if let artist = artist, artist.isNotEmpty {
            addItemToResult(id: .commonIdentifierArtist, space: .common, value: artist as NSCopying & NSObjectProtocol)
        }
        
        if let albumTitle = albumTitle, albumTitle.isNotEmpty {
            addItemToResult(id: .commonIdentifierAlbumName, space: .common, value: albumTitle as NSCopying & NSObjectProtocol)
        }

        //iTunes
        if let userGrouping = userGrouping, userGrouping.isNotEmpty {
            addItemToResult(id: .iTunesMetadataGrouping, space: .iTunes, value: userGrouping as NSCopying & NSObjectProtocol)
        }
        
        if let comments = comments, comments.isNotEmpty {
            addItemToResult(id: .iTunesMetadataUserComment, space: .iTunes, value: comments as NSCopying & NSObjectProtocol)
        }

        if beatsPerMinute > 0 {
            let bpm = NSNumber(value: beatsPerMinute)
            addItemToResult(id: .iTunesMetadataBeatsPerMin, space: .iTunes, value: bpm as NSCopying & NSObjectProtocol)
        }
        
        return result
    }
}


