//
//  AVMetadataIdentifier+id3v2.swift
//  swiftlets
//
//  Created by Frank Vernon on 1/20/18.
//  Copyright © 2018 Frank Vernon. All rights reserved.
//

import Foundation
import MediaPlayer

public extension AVMetadataKeySpace {
    //This not defined in AVMetadataKeySpace for some reason
    public static let iTunesData: AVMetadataKeySpace = AVMetadataKeySpace("itlk")
}

//id3 v2 identifiers: http://id3.org/id3v2-00
//id3 support in AVURLAsset/AVMetadataItem appears to be >v2 but the tags are still interpreted as below
public extension AVMetadataIdentifier {
    public init(id3V2Key key: String) {
        self.init("id3/%00\(key)")
    }
    
    public static let id3V2MetadataAudioEncryption: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "CRA") /* CRA Audio encryption */
    
    public static let id3V2EncryptedMetaFrame: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "CRM") /* CRM Encrypted meta frame */
    
    public static let id3V2MetadataAttachedPicture: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "PIC") /* PIC Attached picture */
    
    public static let id3V2MetadataComments: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "COM") /* COM Comments */
    
    public static let id3V2MetadataEqualization: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "EQU") /* EQU Equalization */
    
    public static let id3V2MetadataEventTimingCodes: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "ETC") /* ETC Event timing codes */
    
    public static let id3V2MetadataGeneralEncapsulatedObject: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "GEO") /* GEO General encapsulated object */
    
    public static let id3V2MetadataInvolvedPeopleList_v23: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "IPL") /* IPL Involved people list */
    
    public static let id3V2MetadataLink: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "LNK") /* LNK Linked information */
    
    public static let id3V2MetadataMusicCDIdentifier: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "MCI") /* MCI Music CD Identifier */
    
    public static let id3V2MetadataMPEGLocationLookupTable: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "MLL") /* MLL MPEG location lookup table */
    
    public static let id3V2MetadataPlayCounter: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "CNT") /* CNT Play counter */
    
    public static let id3V2MetadataPopularimeter: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "POP") /* POP Popularimeter */
    
    public static let id3V2MetadataRecommendedBufferSize: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "BUF") /* BUF Recommended buffer size */
    
    public static let id3V2MetadataRelativeVolumeAdjustment: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "RVA") /* RVA Relative volume adjustment */
    
    public static let id3V2MetadataReverb: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "REV") /* REV Reverb */
    
    public static let id3V2MetadataSynchronizedLyric: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "SLT") /* SLT Synchronized lyric/text */
    
    public static let id3V2MetadataSynchronizedTempoCodes: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "STC") /* STC Synced tempo codes */
    
    public static let id3V2MetadataAlbumTitle: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TAL") /* TAL Album/Movie/Show title */
    
    public static let id3V2MetadataBeatsPerMinute: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TBP") /* TBP BPM (Beats Per Minute)*/
    
    public static let id3V2MetadataComposer: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TCM") /* TCM Composer */
    
    public static let id3V2MetadataContentType: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TCO") /* TCO Content type */
    
    public static let id3V2MetadataCopyright: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TCR") /* TCR Copyright message */
    
    public static let id3V2MetadataDate: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TDA") /* TDA Date */
    
    public static let id3V2MetadataPlaylistDelay: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TDY") /* TDY Playlist delay */
    
    public static let id3V2MetadataEncodedBy: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TEN") /* TEN Encoded by */
    
    public static let id3V2MetadataLyricist: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TXT") /* TXT Lyricist/text writer */
    
    public static let id3V2MetadataFileType: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TFT") /* TFT File type */
    
    public static let id3V2MetadataTime: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TIM") /* TIM Time */
    
    public static let id3V2MetadataContentGroupDescription: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TT1") /* TT1 Content group description */
    
    public static let id3V2MetadataTitleDescription: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TT2") /* TT2 Title/Songname/Content description */
    
    public static let id3V2MetadataSubTitle: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TT3") /* TT3 Subtitle/Description refinement */
    
    public static let id3V2MetadataInitialKey: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TKE") /* TKE Initial key */
    
    public static let id3V2MetadataLanguage: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TLA") /* TLA Language(s) */
    
    public static let id3V2MetadataLength: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TLE") /* TLE Length */
    
    public static let id3V2MetadataMediaType: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TMT") /* TMT Media type */
    
    public static let id3V2MetadataOriginalAlbumTitle: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TOT") /* TOT Original album/Movie/Show title */
    
    public static let id3V2MetadataOriginalFilename: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TOF") /* TOF Original filename */
    
    public static let id3V2MetadataOriginalLyricist: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TOL") /* TOL Original Lyricist(s)/text writer(s)*/
    
    public static let id3V2MetadataOriginalArtist: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TOA") /* TOA Original artist(s)/performer(s)*/
    
    public static let id3V2MetadataOriginalReleaseYear: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TOR") /* TOR Original release year */
    
    public static let id3V2MetadataLeadPerformer: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TP1") /* TP1 Lead artist(s)/Lead performer(s)/Soloist(s)/Performing group*/
    
    public static let id3V2MetadataBand: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TP2") /* TP2 Band/Orchestra/Accompaniment */
    
    public static let id3V2MetadataConductor: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TP3") /* TP3 Conductor/Performer refinement */
    
    public static let id3V2MetadataModifiedBy: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TP4") /* TP4 Interpreted, remixed, or otherwise modified by */
    
    public static let id3V2MetadataPartOfASet: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TPA") /* TPA Part of a set */
    
    public static let id3V2MetadataPublisher: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TPB") /* TPB Publisher */
    
    public static let id3V2MetadataTrackNumber: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TRK") /* TRK Track number/Position in set */
    
    public static let id3V2MetadataRecordingDates: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TRD") /* TRD Recording dates */
    
    public static let id3V2MetadataSize: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TSI") /* TSI Size */
    
    public static let id3V2MetadataInternationalStandardRecordingCode: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TRC") /* TRC ISRC (International Standard Recording Code)*/
    
    public static let id3V2MetadataEncodedWith: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TSS") /* TSS Software/hardware and settings used for encoding */
    
    public static let id3V2MetadataYear: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TYE") /* TYE Year */
    
    public static let id3V2MetadataUserText: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TXX") /* TXX User defined text information frame */
    
    public static let id3V2MetadataUniqueFileIdentifier: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "UFI") /* UFI Unique file identifier */
    
    public static let id3V2MetadataUnsynchronizedLyric: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "ULT") /* ULT Unsychronized lyric/text transcription */
    
    public static let id3V2MetadataCommercialInformation: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WCM") /* WCM Commercial information */
    
    public static let id3V2MetadataCopyrightInformation: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WCP") /* WCP Copyright/Legal information */
    
    public static let id3V2MetadataOfficialAudioFileWebpage: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WAF") /* WAF Official audio file webpage */
    
    public static let id3V2MetadataOfficialArtistWebpage: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WAR") /* WAR Official artist/performer webpage */
    
    public static let id3V2MetadataOfficialAudioSourceWebpage: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WAS") /* WAS Official audio source webpage */
    
    public static let id3V2MetadataOfficialPublisherWebpage: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WPB") /* WPB Publishers official webpage */
    
    public static let id3V2MetadataUserURL: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WXX") /* WXX User defined URL link frame */
    
}
