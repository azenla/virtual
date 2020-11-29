//
//  VirtualDisk.swift
//  VirtualCore
//
//  Created by Kenneth Endfinger on 11/28/20.
//

import Foundation

public struct VirtualDiskProfile {
  public var diskImageURL: URL
  public var readOnly: Bool

  public init(_ diskImageURL: URL, readOnly: Bool = false) {
    self.diskImageURL = diskImageURL
    self.readOnly = readOnly
  }
}
