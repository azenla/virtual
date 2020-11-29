//
//  VirtualMachine.swift
//  VirtualCore
//
//  Created by Kenneth Endfinger on 11/28/20.
//

import Foundation
import Virtualization

public struct VirtualMachine {
  public let profile: VirtualProfile
  public let machine: VZVirtualMachine

  public static func create(_ profile: VirtualProfile) throws -> VirtualMachine {
    let bootloader = VZLinuxBootLoader(kernelURL: profile.boot.kernelFileURL)
    bootloader.initialRamdiskURL = profile.boot.ramdiskFileURL
    if profile.boot.kernelCommandLine != nil {
      bootloader.commandLine = profile.boot.kernelCommandLine!
    }

    let configuration = VZVirtualMachineConfiguration()
    configuration.bootLoader = bootloader
    configuration.cpuCount = Int(profile.cores)
    configuration.memorySize = profile.memory * 1024 * 1024

    if profile.coreDevices.enableMemoryBalloon {
      configuration.memoryBalloonDevices = [
        VZVirtioTraditionalMemoryBalloonDeviceConfiguration()
      ]
    }

    if profile.coreDevices.enableEntropyDevice {
      configuration.entropyDevices = [
        VZVirtioEntropyDeviceConfiguration()
      ]
    }

    var storageDevices: [VZStorageDeviceConfiguration] = []
    for disk in profile.disks {
      let attachment = try VZDiskImageStorageDeviceAttachment(url: disk.diskImageURL, readOnly: disk.readOnly)
      let storage = VZVirtioBlockDeviceConfiguration(attachment: attachment)
      storageDevices.append(storage)
    }

    var networkDevices: [VZNetworkDeviceConfiguration] = []
    for network in profile.networks {
      let networkDevice = VZVirtioNetworkDeviceConfiguration()
      switch network.type {
      case .NAT:
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
      }

      if let macAddressString = network.macAddress {
        if let macAddress = VZMACAddress(string: macAddressString) {
          networkDevice.macAddress = macAddress
        }
      }
      networkDevices.append(networkDevice)
    }

    configuration.storageDevices = storageDevices
    configuration.networkDevices = networkDevices

    let machine = VZVirtualMachine(configuration: configuration)

    return VirtualMachine(profile: profile, machine: machine)
  }
  
  public func start() {
    machine.start { result in
      switch result {
      case .success:
        NSLog("Virtual Machine Started")
        break
      case let .failure(error):
        NSLog("Virtual Machine Failure: \(error)")
        break
      }
    }
  }

  public func stateAsString() -> String {
    switch machine.state {
    case .stopped:
      return "Stopped"
    case .running:
      return "Running"
    case .paused:
      return "Paused"
    case .error:
      return "Error"
    case .starting:
      return "Starting"
    case .pausing:
      return "Pausing"
    case .resuming:
      return "Resuming"
    @unknown default:
      return "Unknown"
    }
  }
}
