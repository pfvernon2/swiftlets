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
    public enum informationalStatus {
        case continuing
        case switchingProtocols
        case processing
        case checkpoint
        case unknown(Int)
        
        init(statusCode: Int) {
            switch statusCode {
            case 100:
                self = .continuing
            case 101:
                self = .switchingProtocols
            case 102:
                self = .processing
            case 103:
                self = .checkpoint
            default:
                self = .unknown(statusCode)
            }
        }
    }
    
    public enum successStatus {
        case ok
        case created
        case accepted
        case nonAuthoritative
        case noContent
        case resetContent
        case partialContent
        case multiStatus
        case alreadyReported
        case imUsed
        case unknown(Int)

        init(statusCode: Int) {
            switch statusCode {
            case 200:
                self = .ok
            case 201:
                self = .created
            case 202:
                self = .accepted
            case 203:
                self = .nonAuthoritative
            case 204:
                self = .noContent
            case 205:
                self = .resetContent
            case 206:
                self = .partialContent
            case 207:
                self = .multiStatus
            case 208:
                self = .alreadyReported
            case 226:
                self = .imUsed
            default:
                self = .unknown(statusCode)
            }
        }
        
        var isOK: Bool {
            get {
                switch self {
                case .ok:
                    return true
                default:
                    return false
                }
            }
        }
    }

    public enum redirectionSatus {
        case multipleChoices
        case movedPermanently
        case found
        case seeOther
        case notModified
        case useProxy
        case switchProxy
        case temporaryRedirect
        case permanentRedirect
        case unknown(Int)
        
        init(statusCode: Int) {
            switch statusCode {
            case 300:
                self = .multipleChoices
            case 301:
                self = .movedPermanently
            case 302:
                self = .found
            case 303:
                self = .seeOther
            case 304:
                self = .notModified
            case 305:
                self = .useProxy
            case 306:
                self = .switchProxy
            case 307:
                self = .temporaryRedirect
            case 308:
                self = .permanentRedirect
            default:
                self = .unknown(statusCode)
            }
        }
    }
    
    public enum clientErrorStatus {
        case badRequest
        case unauthorized
        case paymentRequired
        case forbidden
        case notFound
        case methodNotAllowed
        case notAcceptable
        case proxyAuthenticationRequired
        case requestTimeout
        case conflict
        case gone
        case lengthRequired
        case preconditionFailed
        case payloadTooLarge
        case uriTooLong
        case unsupportedMediaType
        case rangeNotSatisfiable
        case expectationFailed
        case imATeapot
        case imAFox
        case enhanceYourCalm
        case misdirectedRequest
        case unprocessableEntity
        case locked
        case failedDependency
        case upgradeRequired
        case preconditionRequired
        case tooManyRequests
        case requestHeaderFieldsTooLarge
        case unavailableForLegalReasons
        case loginTimeout
        case retryWith
        case redirect
        case noResponse
        case sslCertificateError
        case sslCertificateRequired
        case httpRequestSentToHTTPSPort
        case invalidToken
        case tokenRequired
        case unknown(Int)
        
        init(statusCode: Int) {
            switch statusCode {
            case 400:
                self = .badRequest
            case 401:
                self = .unauthorized
            case 402:
                self = .paymentRequired
            case 403:
                self = .forbidden
            case 404:
                self = .notFound
            case 405:
                self = .methodNotAllowed
            case 406:
                self = .notAcceptable
            case 407:
                self = .proxyAuthenticationRequired
            case 408:
                self = .requestTimeout
            case 409:
                self = .conflict
            case 410:
                self = .gone
            case 411:
                self = .lengthRequired
            case 412:
                self = .preconditionFailed
            case 413:
                self = .payloadTooLarge
            case 414:
                self = .uriTooLong
            case 415:
                self = .unsupportedMediaType
            case 416:
                self = .rangeNotSatisfiable
            case 417:
                self = .expectationFailed
            case 418:
                self = .imATeapot
            case 419:
                self = .imAFox
            case 420:
                self = .enhanceYourCalm
            case 421:
                self = .misdirectedRequest
            case 422:
                self = .unprocessableEntity
            case 423:
                self = .locked
            case 424:
                self = .failedDependency
            case 426:
                self = .upgradeRequired
            case 428:
                self = .preconditionRequired
            case 429:
                self = .tooManyRequests
            case 431:
                self = .requestHeaderFieldsTooLarge
            case 451:
                self = .unavailableForLegalReasons
            case 440:
                self = .loginTimeout
            case 449:
                self = .retryWith
            case 451:
                self = .redirect
            case 444:
                self = .noResponse
            case 495:
                self = .sslCertificateError
            case 496:
                self = .sslCertificateRequired
            case 497:
                self = .httpRequestSentToHTTPSPort
            case 498:
                self = .invalidToken
            case 499:
                self = .tokenRequired
            default:
                self = .unknown(statusCode)
            }
        }
    }

    public enum serverErrorStatus {
        case internalServerError
        case notImplemented
        case badGateway
        case serviceUnavailable
        case gatewayTimeout
        case httpVersionNotSupported
        case variantAlsoNegotiates
        case insufficientStorage
        case loopDetected
        case bandwidthLimitExceeded
        case notExtended
        case networkAuthenticationRequired
        case unknownError
        case webServerIsDown
        case connectionTimedOut
        case originIsUnreachable
        case timeoutOccurred
        case sslHandshakeFailed
        case invalidSSLCertificate
        case railgunError
        case siteIsFrozen
        case unknown(Int)
        
        init(statusCode: Int) {
            switch statusCode {
            case 500:
                self = .internalServerError
            case 501:
                self = .notImplemented
            case 502:
                self = .badGateway
            case 503:
                self = .serviceUnavailable
            case 504:
                self = .gatewayTimeout
            case 505:
                self = .httpVersionNotSupported
            case 506:
                self = .variantAlsoNegotiates
            case 507:
                self = .insufficientStorage
            case 508:
                self = .loopDetected
            case 509:
                self = .bandwidthLimitExceeded
            case 510:
                self = .notExtended
            case 511:
                self = .networkAuthenticationRequired
            case 520:
                self = .unknownError
            case 521:
                self = .webServerIsDown
            case 522:
                self = .connectionTimedOut
            case 523:
                self = .originIsUnreachable
            case 524:
                self = .timeoutOccurred
            case 525:
                self = .sslHandshakeFailed
            case 526:
                self = .invalidSSLCertificate
            case 527:
                self = .railgunError
            case 530:
                self = .siteIsFrozen
            default:
                self = .unknown(statusCode)
            }
        }
        
        var isInternalServerError: Bool {
            get {
                switch self {
                case .internalServerError:
                    return true
                default:
                    return false
                }
            }
        }
    }

    case informational(informationalStatus)
    case success(successStatus)
    case redirection(redirectionSatus)
    case clientError(clientErrorStatus)
    case serverError(serverErrorStatus)
    case unknownClass(Int)

    init(statusCode: Int) {
        switch statusCode {
        case 100..<200:
            self = .informational(HTTPURLReponseStatus.informationalStatus(statusCode: statusCode))
        case 200..<300:
            self = .success(HTTPURLReponseStatus.successStatus(statusCode: statusCode))
        case 300..<400:
            self = .redirection(HTTPURLReponseStatus.redirectionSatus(statusCode: statusCode))
        case 400..<500:
            self = .clientError(HTTPURLReponseStatus.clientErrorStatus(statusCode: statusCode))
        case 500..<600:
            self = .serverError(HTTPURLReponseStatus.serverErrorStatus(statusCode: statusCode))
        default:
            self = .unknownClass(statusCode)
        }
    }
}

public extension HTTPURLResponse {
    var status:HTTPURLReponseStatus {
        return HTTPURLReponseStatus(statusCode: statusCode)
    }
}
