//
//  NSHTTPURLResponse+Utility.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/27/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

/**
 Enumeration of HTTP result values categorized by class of status code. 
 This is useful in processing results of web service calls, for example.
 
 ````
 switch responseStatus {
    case .success:
        //happy path
    
    case .serverError(let serverStatus):
        switch serverStatus {
            case .internalServerError:
                //blame them
 
            case .notImplemented:
                //blame me

            default:
                //blame everyone
        }

    default:
        //what now?
 }
 ````
 */

public enum HTTPURLReponseStatus {

    public enum informationalStatus: Int {
        case continuing = 100
        case switchingProtocols = 101
        case processing = 102
        case checkpoint = 103
    }
    
    public enum successStatus: Int {
        case ok = 200
        case created = 201
        case accepted = 202
        case nonAuthoritative = 203
        case noContent = 204
        case resetContent = 205
        case partialContent = 206
        case multiStatus = 207
        case alreadyReported = 208
        case imUsed = 226

        //test most common case
        var isOK: Bool {
            get {
                self == .ok
            }
        }
    }

    public enum redirectionSatus: Int {
        case multipleChoices = 300
        case movedPermanently = 301
        case found = 302
        case seeOther = 303
        case notModified = 304
        case useProxy = 305
        case switchProxy = 306
        case temporaryRedirect = 307
        case permanentRedirect = 308
    }
    
    public enum clientErrorStatus: Int {
        case badRequest = 400
        case unauthorized = 401
        case paymentRequired = 402
        case forbidden = 403
        case notFound = 404
        case methodNotAllowed = 405
        case notAcceptable = 406
        case proxyAuthenticationRequired = 407
        case requestTimeout = 408
        case conflict = 409
        case gone = 410
        case lengthRequired = 411
        case preconditionFailed = 412
        case payloadTooLarge = 413
        case uriTooLong = 414
        case unsupportedMediaType = 415
        case rangeNotSatisfiable = 416
        case expectationFailed = 417
        case imATeapot = 418
        case imAFox = 419
        case enhanceYourCalm = 420
        case misdirectedRequest = 421
        case unprocessableEntity = 422
        case locked = 423
        case failedDependency = 424
        case upgradeRequired = 426
        case preconditionRequired = 428
        case tooManyRequests = 429
        case requestHeaderFieldsTooLarge = 431
        case loginTimeout = 440
        case noResponse = 444
        case retryWith = 449
        case unavailableForLegalReasons = 451
        case sslCertificateError = 495
        case sslCertificateRequired = 496
        case httpRequestSentToHTTPSPort = 497
        case invalidToken = 498
        case tokenRequired = 499
    }

    public enum serverErrorStatus: Int {
        case internalServerError = 500
        case notImplemented = 501
        case badGateway = 502
        case serviceUnavailable = 503
        case gatewayTimeout = 504
        case httpVersionNotSupported = 505
        case variantAlsoNegotiates = 506
        case insufficientStorage = 507
        case loopDetected = 508
        case bandwidthLimitExceeded = 509
        case notExtended = 510
        case networkAuthenticationRequired = 511
        case unknownError = 520
        case webServerIsDown = 521
        case connectionTimedOut = 522
        case originIsUnreachable = 523
        case timeoutOccurred = 524
        case sslHandshakeFailed = 525
        case invalidSSLCertificate = 526
        case railgunError = 527
        case siteIsFrozen = 530

        var isInternalServerError: Bool {
            get {
                self == .internalServerError
            }
        }
    }

    case informational(informationalStatus)
    case success(successStatus)
    case redirection(redirectionSatus)
    case clientError(clientErrorStatus)
    case serverError(serverErrorStatus)
    case unknown(Int)

    init(statusCode: Int) {
        //default to unknown in the event parsing below fails to categorize the status code
        self = .unknown(statusCode)

        switch statusCode {
        case 100..<200:
            if let info = informationalStatus(rawValue: statusCode) {
                self = .informational(info)
            }

        case 200..<300:
            if let success = successStatus(rawValue: statusCode) {
                self = .success(success)
            }

        case 300..<400:
            if let redirect = redirectionSatus(rawValue: statusCode) {
                self = .redirection(redirect)
            }

        case 400..<500:
            if let clientError = clientErrorStatus(rawValue: statusCode) {
                self = .clientError(clientError)
            }

        case 500..<600:
            if let serverError = serverErrorStatus(rawValue: statusCode) {
                self = .serverError(serverError)
            }

        default:
            //set to .unknown handled above
            break
        }
    }
    
    func isSuccess() -> Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }

    func isSuccessOK() -> Bool {
        switch self {
        case .success(let value):
            return value.isOK
        default:
            return false
        }
    }

}

//Extension of HTTPURLResponse to return custom response status enum
public extension HTTPURLResponse {
    var status:HTTPURLReponseStatus {
        HTTPURLReponseStatus(statusCode: statusCode)
    }
}

//Extension of StringInterpolation to return localized strings for HTTPURLReponseStatus values
extension String.StringInterpolation {
    mutating func appendInterpolation(_ status: HTTPURLReponseStatus.successStatus) {
        let localized = HTTPURLResponse.localizedString(forStatusCode: status.rawValue);
        appendInterpolation(localized)
    }

    mutating func appendInterpolation(_ status: HTTPURLReponseStatus.informationalStatus) {
        let localized = HTTPURLResponse.localizedString(forStatusCode: status.rawValue);
        appendInterpolation(localized)
    }

    mutating func appendInterpolation(_ status: HTTPURLReponseStatus.redirectionSatus) {
        let localized = HTTPURLResponse.localizedString(forStatusCode: status.rawValue);
        appendInterpolation(localized)
    }

    mutating func appendInterpolation(_ status: HTTPURLReponseStatus.clientErrorStatus) {
        let localized = HTTPURLResponse.localizedString(forStatusCode: status.rawValue);
        appendInterpolation(localized)
    }

    mutating func appendInterpolation(_ status: HTTPURLReponseStatus.serverErrorStatus) {
        let localized = HTTPURLResponse.localizedString(forStatusCode: status.rawValue);
        appendInterpolation(localized)
    }

    mutating func appendInterpolation(_ httpResponse: HTTPURLReponseStatus) {
        switch httpResponse {
        case .informational(let informational):
            appendInterpolation("\(informational)")
        case .success(let success):
            appendInterpolation("\(success)")
        case .redirection(let redirection):
            appendInterpolation("\(redirection)")
        case .clientError(let clientError):
            appendInterpolation("\(clientError)")
        case .serverError(let serverError):
            appendInterpolation("\(serverError)")
        case .unknown(let unknown):
            appendInterpolation(HTTPURLResponse.localizedString(forStatusCode: unknown))
        }
    }
}

//Extension to print localized error string HTTPURLResponse
extension String.StringInterpolation {
    mutating func appendInterpolation(_ httpResponse: HTTPURLResponse) {
        let localized = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode);
        appendInterpolation(localized)
    }
}
