//
//  AVAudioFile+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/16/20.
//  Copyright © 2020 Frank Vernon. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

public let kDefaultNoiseFloor: Float = -50.0

public extension AVAudioFile {
    enum SwiftletsAudioFileError: Error {
        case invalidFormat
        case outOfMemory
        case invalidConverter
    }
    
    ///Render file as mono waveform image. There are many like it, this is mine.
    /// - note: This is optimized for speed at the expense of memory overhead. As much as 2x the file size may reside
    ///         in memory for a brief time while the samples are manipulated. All sample data is released before the image is returned.
    func waveFormImage(imageSize: CGSize,
                       graphColor: UIColor,
                       scaleToDisplay: Bool = true,
                       displayInDB: Bool = false,
                       noiseFloor: Float = kDefaultNoiseFloor) -> UIImage? {
        guard var samples = try? samples(asMono: true) else {
            return nil
        }
        
        //number of pixels required to draw each "sample"
        let lineWidth: CGFloat = 1.0
        let lineSpacing: CGFloat = 1.0
        let pixelsPerSample = lineWidth + lineSpacing
        
        //Number of samples per pixel for decimation
        let samplesPerPixel = samples.count / Int(imageSize.width/pixelsPerSample)

        //decimate samples to correleate with number of pixels in width of image
        // this optimizes for the number of points we have to draw
        decimate(samples: &samples,
                 samplesPerPixel: samplesPerPixel,
                 convertToDB: true,
                 noiseFloor: noiseFloor)
        
        if !displayInDB {
            //convert DB to gain/power and (re-)clip at the specified dynamic range
            samples = samples.map { pow(10.0, $0/20.0) }
            var floor: Float = .zero
            var ceil: Float = abs(noiseFloor)
            vDSP_vclip(samples, 1, &floor, &ceil, &samples, 1, vDSP_Length(samples.count));
        }
        
        //normalize samples to the height of the image so we fill the image as best we can
        let imageMaxHeight = floor(imageSize.height)
        let maxAmplitude = vDSP.maximum(samples)
        let normalization = Float(imageMaxHeight) / maxAmplitude
        vDSP.multiply(normalization, samples, result: &samples)
        
        //generate waveform
        return UIGraphicsImageContext(size: imageSize, opaque: false, scale:scaleToDisplay ? 0.0 : 1.0) { (context) in
            context.setAllowsAntialiasing(true)
            
            let center = imageMaxHeight.halved
            let path = UIBezierPath()
            for (index, sample) in samples.enumerated() {
                let offset = CGFloat(index)
                let amplitude = max(CGFloat(sample), 1.0)
                
                let x = offset * pixelsPerSample
                let y = center - amplitude.halved
                
                path.addVerticalLine(at: CGPoint(x: x, y: y), ofHeight: amplitude)
            }
            path.close()
            
            path.lineWidth = lineWidth
            
            graphColor.setStroke()
            path.stroke()
        }
    }

    ///Read entire file into buffer of Float32 based on the format of the file. By default returns a mono representation of the samples.
    func samples(asMono mono: Bool = true) throws -> [Float] {
        guard let fileFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                             sampleRate: fileFormat.sampleRate,
                                             channels: fileFormat.channelCount,
                                             interleaved: false) else {
                                                throw SwiftletsAudioFileError.invalidFormat
        }
        
        guard var buf = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: UInt32(length)) else {
            throw SwiftletsAudioFileError.outOfMemory
        }
        
        try read(into: buf)
        
        //TODO: Make this more efficient on memory by doing mono conversion during chunked file read
        if mono && fileFormat.channelCount > 1 {
            guard let monoFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                                 sampleRate: fileFormat.sampleRate,
                                                 channels: 1,
                                                 interleaved: false) else {
                                                    throw SwiftletsAudioFileError.invalidFormat
            }
            
            guard let monoBuf = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: buf.frameLength) else {
                throw SwiftletsAudioFileError.outOfMemory
            }
            
            guard let converter = AVAudioConverter(from: buf.format, to: monoBuf.format) else {
                throw SwiftletsAudioFileError.invalidConverter
            }
            
            try converter.convert(to: monoBuf, from: buf)
            
            buf = monoBuf
        }
        
        return Array(UnsafeBufferPointer(start: buf.floatChannelData?[0],
                                         count:Int(buf.frameLength)))
    }
    
    //Somewhat messy routine to manipulate the samples from the file into more manageable form
    // for image rendering. Unlikely to be of use outside this file so marked private for now.
    // Note that all work is done in place on the array of samples passed in.
    private func decimate(samples: inout [Float], samplesPerPixel: Int, convertToDB: Bool, noiseFloor: Float = kDefaultNoiseFloor) {
        let downSampledLength = samples.count / samplesPerPixel
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        
        if convertToDB {
            //convert to DB
            let sampleCount = vDSP_Length(samples.count)
            vDSP_vabs(samples, 1, &samples, 1, sampleCount);
            var zero: Float = 1;
            vDSP_vdbcon(samples, 1, &zero, &samples, 1, sampleCount, 1);
            
            //decimate samples
            vDSP_desamp(samples,
                        vDSP_Stride(samplesPerPixel),
                        filter,
                        &samples,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))
            //operating in place and trimming buffer is better on memory and slightly faster than duplicating data
            samples.removeLast(samples.count - downSampledLength)
            
            // clip at noise floor then
            // add noisefloor to make values positive amplitude in db
            var floor: Float = noiseFloor
            var ceil: Float = .zero
            vDSP_vclip(samples, 1, &floor, &ceil, &samples, 1, vDSP_Length(samples.count));
            vDSP.add(abs(noiseFloor), samples, result: &samples)
        }
        else {
            //decimate samples
            vDSP_desamp(samples,
                        vDSP_Stride(samplesPerPixel),
                        filter,
                        &samples,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))
            samples.removeLast(samples.count - downSampledLength)

            vDSP_vabs(samples, 1, &samples, 1, vDSP_Length(downSampledLength));
        }
    }
}
