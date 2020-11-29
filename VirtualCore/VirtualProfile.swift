//
//  VirtualProfile.swift
//  VirtualCore
//
//  Created by Kenneth Endfinger on 11/28/20.
//

import Foundation

public struct VirtualProfile {
  public var cores: UInt64
  public var memory: UInt64
  public var boot: VirtualBootProfile

  public init(cores: UInt64, memory: UInt64, boot: VirtualBootProfile) {
    self.cores = cores
    self.memory = memory
    self.boot = boot
  }

  public var coreDevices = VirtualCoreDeviceProfile()
  public var disks: [VirtualDiskProfile] = []
  public var networks: [VirtualNetworkProfile] = []
}
