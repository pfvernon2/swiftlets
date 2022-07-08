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
    ///Calls provided block with per channel floatChannelData
    func performTransform(_ block: (UnsafeMutablePointer<Float>) -> Swift.Void) {
        guard let floatChannelData = floatChannelData else {
            return
        }
        
        for i in 0..<Int(format.channelCount) {
            block(floatChannelData[i])
        }
    }
    
    ///Returns floatChannelData as array of arrays for ease of handling. Copies data.
    ///
    ///See: `AVAudioPCMBuffer.floatChannelData` for details and limitations.
    var floatChannelArray: [[Float]]? {
        var result = [[Float]](capacity: Int(format.channelCount))
        
        performTransform {
            result.append(Array(UnsafeBufferPointer(start: $0,
                                                    count: Int(frameLength))))
        }
                
        return result.isEmpty ? nil : result
    }
    
    func rmsPowerValues(scale: Float = -80.0) -> [Float]? {
        var result = Array<Float>(capacity: Int(format.channelCount))
        
        performTransform {
            var avgValue:Float32 = .zero
            vDSP_rmsqv($0, 1, &avgValue, UInt(frameLength))
            var power: Float = -100.0
            if avgValue != .zero {
                power = 20.0 * log10f(avgValue)
            }
            
            result.append(scalePowerValue(power: power, min: scale))
        }
        
        return result.isEmpty ? nil : result
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
    
    ///Locates frame positions of first and last samples in the buffer with non-zero values.
    func silenceTrimPositions() -> (AVAudioFramePosition, AVAudioFramePosition) {
        guard let start = silenceTrimPosition(fromTail: false),
              let end = silenceTrimPosition(fromTail: true) else {
            return (.zero, AVAudioFramePosition(frameLength))
        }
        
        return (start, end)
    }
    
    ///Locates frame position of first or last sample in the buffer with a non-zero value.
    ///
    /// - parameter fromTail - If true scans backward from the end of the buffer for
    /// contigous silence, if false scans forward from start of the buffer.
    ///
    /// - note: This works directly on the buffer. No copy of data is made and buffer is not modified.
    func silenceTrimPosition(fromTail: Bool = false) -> AVAudioFramePosition? {
        guard let floatChannelData = floatChannelData else {
            return nil
        }

        let framesEnd: AVAudioFramePosition = AVAudioFramePosition(frameLength)

        //Setup the forward/reverse walk of the channel samples
        // based on fromTail parameter
        let start: AVAudioFramePosition
        var end: AVAudioFramePosition
        let stride: Int
        switch fromTail {
        case true:
            start = framesEnd - 1
            end = .zero
            stride = -1
        case false:
            start = .zero
            end = framesEnd - 1
            stride = 1
        }
        
        //Walk all channels looking for earliest/latest non-zero sample
        var foundSample = false
        for i in 0..<Int(format.channelCount) {
            for j in Swift.stride(from: start, to: end, by: stride) {
                if floatChannelData[i][Int(j)] != .zero {
                    // reset end to avoid walking any further
                    // than necessary in subsequent channels
                    end = j
                    foundSample = true
                    break
                }
            }
        }
        
        guard foundSample else {
            return nil
        }
        
        return end
    }
    
    ///Decimate all channels in buffer based on factor supplied.
    ///
    /// - note: frameLength of the buffer will be modified before return
    ///         indicating new buffer length.
    func decimateBy(_ factor: Int) {
        var decimatedLength: AVAudioFrameCount = frameLength
        performTransform {
            decimatedLength = decimate(samples: $0,
                                       decimationFactor: factor)
        }
                
        frameLength = decimatedLength
    }
    
    ///Decimate samples based on factor supplied.
    ///
    /// - returns: New frameLength
    ///
    /// - note: All work done in place on the array passed in. On return array is resized to
    ///         represent only the decimated samples.
    func decimate(samples: UnsafeMutablePointer<Float>, decimationFactor: Int) -> AVAudioFrameCount {
        let filterLength = vDSP_Length(decimationFactor)
        let decimatedLength = vDSP_Length((UInt(frameLength) - filterLength) / filterLength) + 1

        let filter = [Float](repeating: 1 / Float(filterLength),
                             count: Int(filterLength))

        //decimate samples
        vDSP_desamp(samples,
                    vDSP_Stride(decimationFactor),
                    filter,
                    samples,
                    decimatedLength,
                    filterLength)
        
        return AVAudioFrameCount(decimatedLength)
    }
}
