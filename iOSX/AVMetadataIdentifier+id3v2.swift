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
    static let iTunesData: AVMetadataKeySpace = AVMetadataKeySpace("itlk")
}

//id3 v2 identifiers: http://id3.org/id3v2-00
//id3 support in AVURLAsset/AVMetadataItem appears to be >v2 but the tags are still interpreted as below
public extension AVMetadataIdentifier {
    init(id3V2Key key: String) {
        self.init("id3/%00\(key)")
    }
    
    static let id3V2MetadataAudioEncryption: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "CRA") /* CRA Audio encryption */
    
    static let id3V2EncryptedMetaFrame: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "CRM") /* CRM Encrypted meta frame */
    
    static let id3V2MetadataAttachedPicture: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "PIC") /* PIC Attached picture */
    
    static let id3V2MetadataComments: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "COM") /* COM Comments */
    
    static let id3V2MetadataEqualization: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "EQU") /* EQU Equalization */
    
    static let id3V2MetadataEventTimingCodes: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "ETC") /* ETC Event timing codes */
    
    static let id3V2MetadataGeneralEncapsulatedObject: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "GEO") /* GEO General encapsulated object */
    
    static let id3V2MetadataInvolvedPeopleList_v23: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "IPL") /* IPL Involved people list */
    
    static let id3V2MetadataLink: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "LNK") /* LNK Linked information */
    
    static let id3V2MetadataMusicCDIdentifier: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "MCI") /* MCI Music CD Identifier */
    
    static let id3V2MetadataMPEGLocationLookupTable: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "MLL") /* MLL MPEG location lookup table */
    
    static let id3V2MetadataPlayCounter: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "CNT") /* CNT Play counter */
    
    static let id3V2MetadataPopularimeter: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "POP") /* POP Popularimeter */
    
    static let id3V2MetadataRecommendedBufferSize: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "BUF") /* BUF Recommended buffer size */
    
    static let id3V2MetadataRelativeVolumeAdjustment: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "RVA") /* RVA Relative volume adjustment */
    
    static let id3V2MetadataReverb: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "REV") /* REV Reverb */
    
    static let id3V2MetadataSynchronizedLyric: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "SLT") /* SLT Synchronized lyric/text */
    
    static let id3V2MetadataSynchronizedTempoCodes: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "STC") /* STC Synced tempo codes */
    
    static let id3V2MetadataAlbumTitle: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TAL") /* TAL Album/Movie/Show title */
    
    static let id3V2MetadataBeatsPerMinute: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TBP") /* TBP BPM (Beats Per Minute)*/
    
    static let id3V2MetadataComposer: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TCM") /* TCM Composer */
    
    static let id3V2MetadataContentType: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TCO") /* TCO Content type */
    
    static let id3V2MetadataCopyright: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TCR") /* TCR Copyright message */
    
    static let id3V2MetadataDate: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TDA") /* TDA Date */
    
    static let id3V2MetadataPlaylistDelay: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TDY") /* TDY Playlist delay */
    
    static let id3V2MetadataEncodedBy: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TEN") /* TEN Encoded by */
    
    static let id3V2MetadataLyricist: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TXT") /* TXT Lyricist/text writer */
    
    static let id3V2MetadataFileType: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TFT") /* TFT File type */
    
    static let id3V2MetadataTime: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TIM") /* TIM Time */
    
    static let id3V2MetadataContentGroupDescription: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TT1") /* TT1 Content group description */
    
    static let id3V2MetadataTitleDescription: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TT2") /* TT2 Title/Songname/Content description */
    
    static let id3V2MetadataSubTitle: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TT3") /* TT3 Subtitle/Description refinement */
    
    static let id3V2MetadataInitialKey: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TKE") /* TKE Initial key */
    
    static let id3V2MetadataLanguage: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TLA") /* TLA Language(s) */
    
    static let id3V2MetadataLength: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TLE") /* TLE Length */
    
    static let id3V2MetadataMediaType: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TMT") /* TMT Media type */
    
    static let id3V2MetadataOriginalAlbumTitle: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TOT") /* TOT Original album/Movie/Show title */
    
    static let id3V2MetadataOriginalFilename: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TOF") /* TOF Original filename */
    
    static let id3V2MetadataOriginalLyricist: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TOL") /* TOL Original Lyricist(s)/text writer(s)*/
    
    static let id3V2MetadataOriginalArtist: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TOA") /* TOA Original artist(s)/performer(s)*/
    
    static let id3V2MetadataOriginalReleaseYear: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TOR") /* TOR Original release year */
    
    static let id3V2MetadataLeadPerformer: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TP1") /* TP1 Lead artist(s)/Lead performer(s)/Soloist(s)/Performing group*/
    
    static let id3V2MetadataBand: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TP2") /* TP2 Band/Orchestra/Accompaniment */
    
    static let id3V2MetadataConductor: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TP3") /* TP3 Conductor/Performer refinement */
    
    static let id3V2MetadataModifiedBy: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TP4") /* TP4 Interpreted, remixed, or otherwise modified by */
    
    static let id3V2MetadataPartOfASet: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TPA") /* TPA Part of a set */
    
    static let id3V2MetadataPublisher: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TPB") /* TPB Publisher */
    
    static let id3V2MetadataTrackNumber: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TRK") /* TRK Track number/Position in set */
    
    static let id3V2MetadataRecordingDates: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TRD") /* TRD Recording dates */
    
    static let id3V2MetadataSize: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TSI") /* TSI Size */
    
    static let id3V2MetadataInternationalStandardRecordingCode: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TRC") /* TRC ISRC (International Standard Recording Code)*/
    
    static let id3V2MetadataEncodedWith: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TSS") /* TSS Software/hardware and settings used for encoding */
    
    static let id3V2MetadataYear: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TYE") /* TYE Year */
    
    static let id3V2MetadataUserText: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "TXX") /* TXX User defined text information frame */
    
    static let id3V2MetadataUniqueFileIdentifier: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "UFI") /* UFI Unique file identifier */
    
    static let id3V2MetadataUnsynchronizedLyric: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "ULT") /* ULT Unsychronized lyric/text transcription */
    
    static let id3V2MetadataCommercialInformation: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WCM") /* WCM Commercial information */
    
    static let id3V2MetadataCopyrightInformation: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WCP") /* WCP Copyright/Legal information */
    
    static let id3V2MetadataOfficialAudioFileWebpage: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WAF") /* WAF Official audio file webpage */
    
    static let id3V2MetadataOfficialArtistWebpage: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WAR") /* WAR Official artist/performer webpage */
    
    static let id3V2MetadataOfficialAudioSourceWebpage: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WAS") /* WAS Official audio source webpage */
    
    static let id3V2MetadataOfficialPublisherWebpage: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WPB") /* WPB Publishers official webpage */
    
    static let id3V2MetadataUserURL: AVMetadataIdentifier = AVMetadataIdentifier(id3V2Key: "WXX") /* WXX User defined URL link frame */
    
}
