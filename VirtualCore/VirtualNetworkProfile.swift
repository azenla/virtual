//
//  VirtualNetworkProfile.swift
//  VirtualCore
//
//  Created by Kenneth Endfinger on 11/28/20.
//

import Foundation

public struct VirtualNetworkProfile {
  public enum NetworkType {
    case NAT
  }

  public var type: NetworkType
  public var macAddress: String?

  public init(type: NetworkType) {
    self.type = type
  }
}
