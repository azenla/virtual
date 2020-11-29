//
//  VirtualBootProfile.swift
//  VirtualCore
//
//  Created by Kenneth Endfinger on 11/28/20.
//

import Foundation

public struct VirtualBootProfile {
  public let kernelFileURL: URL
  public var ramdiskFileURL: URL?
  public var kernelCommandLine: String?

  public init(kernelFileURL: URL) {
    self.kernelFileURL = kernelFileURL
  }
}
