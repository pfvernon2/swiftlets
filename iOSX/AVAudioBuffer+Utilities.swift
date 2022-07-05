//
//  AVAudioBuffer+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/3/22.
//  Copyright © 2022 Frank Vernon. All rights reserved.
//

import Foundation
import AVFAudio
import Accelerate

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
    
    func rmsPowerValues(scale: Float = -80.0) -> [Float]? {
        guard let floatChannelData = floatChannelData else {
            return nil
        }
        
        let numChannels: Int = Int(format.channelCount)
        var result = Array<Float>(capacity: numChannels)
        
        for i in 0..<numChannels {
            let samples = floatChannelData[i]

            var avgValue:Float32 = .zero
            vDSP_rmsqv(samples, 1, &avgValue, UInt(frameLength))
            var power: Float = -100.0
            if avgValue != .zero {
                power = 20.0 * log10f(avgValue)
            }
            
            result.append(scalePowerValue(power: power, min: scale))
        }
        
        return result
    }
    
    private func scalePowerValue(power: Float, min: Float) -> Float {
        guard power.isFinite else {
            return .zero
        }

        switch power {
        case _ where power < min:
            return .zero
        case _ where power > 1.0:
            return 1.0
        default:
            return (abs(min) - abs(power)) / abs(min)
        }
    }
    
    ///Locates frame positions of first and last samples in the file with non-zero values. These frame positions can be used
    ///as start/stop positions on playback to effectively trim silence without modifying the file contents.
    ///
    ///This works directly on the buffer. No copy of data is made and buffer is not modified.
    func silenceTrimPositions() -> (AVAudioFramePosition, AVAudioFramePosition) {
        guard let floatChannelData = floatChannelData else {
            return (.zero, AVAudioFramePosition(frameLength))
        }
        
        let framesEnd: AVAudioFramePosition = AVAudioFramePosition(frameLength)
        var start: AVAudioFramePosition = framesEnd
        var end: AVAudioFramePosition = .zero

        //Walk samples in each channel searching for start/end of channel
        for i in 0..<Int(format.channelCount) {
            //head
            for j in 0..<start {
                if floatChannelData[i][Int(j)] != .zero {
                    //walk back to previous zero value sample to ensure start at zero crossing
                    start = j > .zero ? j - 1 : .zero
                    break
                }
            }
            
            //tail
            for j in Swift.stride(from: framesEnd-1, to: end, by: -1) {
                if floatChannelData[i][Int(j)] != .zero {
                    //walk back to previous zero value sample to ensure end at zero crossing
                    end = j < framesEnd ? j + 1 : framesEnd
                    break
                }
            }
        }

        return (start, end)
    }
}
