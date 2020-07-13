//
//  MPMediaItem+Util.swift
//  swiftlets
//
//  Created by Frank Vernon on 4/25/20.
//  Copyright © 2020 Frank Vernon. All rights reserved.
//

import Foundation
import MediaPlayer

extension String {
    func sha256() -> String {
        guard let data:Data = self.data(using: String.Encoding.utf8) else {
            return String()
        }
        
        return data.sha256()
    }
}

extension MPMediaItem {
    /**
     Generate a hash value likely to define a media item uniquely which is unlikley to change unless the
     track and/or its metadata changes significantly.
     
     In my ananlysis, tracklength (in milliseconds) was highly unique but not 100% reliable. Track name,
     artist, and album are also added to the resulting hash to increase uniqueness.
     
     Rationalle: Track name, artist and album, are likely to change only rarely and most likely
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

        //Hash Title:Artist:Album:TrackLength with record seperators
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
    
    func exportFromMediaLibrary(to destinationDir: URL, completion: @escaping (URL?)->Swift.Void) {
        guard let assetURL = assetURL else {
            completion(nil)
            return
        }
        
        guard let exporter = AVAssetExportSession(asset: AVAsset(url: assetURL),
                                                  presetName: AVAssetExportPresetAppleM4A) else
        {
            completion(nil)
            return
        }
        exporter.shouldOptimizeForNetworkUse = false;
        exporter.outputFileType = AVFileType.m4a
        
        exporter.outputURL = destinationDir
            .appendingPathComponent(fileName())
            .appendingPathExtension("m4a")
        
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                guard exporter.error == nil else {
                    completion(nil)
                    return
                }
                completion(exporter.outputURL)
            }
        }
    }
}
