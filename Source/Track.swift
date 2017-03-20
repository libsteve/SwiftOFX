//
//  Track.swift
//  SwiftOFX
//
//  Created by Steve Brunwasser on 3/15/17.
//  Copyright © 2017 Steve Brunwasser. All rights reserved.
//

import Foundation

enum Track<Continuation, Diversion> {
  case forward(Continuation)
  case divert(Diversion)
}

extension Track {
  func map<T>(_ transform: (Continuation) throws -> T) rethrows -> Track<T, Diversion> {
    switch self {
    case let .forward(continuation): return .forward(try transform(continuation))
    case let .divert(diversion): return .divert(diversion)
    }
  }

  func flatMap<T>(_ transform: (Continuation) throws -> Track<T, Diversion>) rethrows -> Track<T, Diversion> {
    switch self {
    case let .forward(continuation): return try transform(continuation)
    case let .divert(diversion): return .divert(diversion)
    }
  }
}
