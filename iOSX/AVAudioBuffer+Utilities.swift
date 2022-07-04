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
}
