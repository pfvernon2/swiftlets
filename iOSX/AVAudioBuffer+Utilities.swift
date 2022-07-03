//
//  AVAudioBuffer+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/3/22.
//  Copyright © 2022 Frank Vernon. All rights reserved.
//

import Foundation
import AVFAudio

public extension AVAudioPCMBuffer {
    ///Returns floatChannelData as array of arrays for ease of handling. Copies data.
    ///
    ///See: `AVAudioPCMBuffer.floatChannelData` for details and limitations.
    var floatChannelArray: [[Float]]? {
        guard let floatChannelData = floatChannelData else {
            return nil
        }
        
        var result = [[Float]](capacity: Int(format.channelCount))
        for channel in 0..<Int(format.channelCount) {
            result.append(Array(UnsafeBufferPointer(start: floatChannelData[channel],
                                                    count: Int(frameLength))))
        }
        return result
    }
}
