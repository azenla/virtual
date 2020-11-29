//
//  VirtualSystem.swift
//  virtual
//
//  Created by Kenneth Endfinger on 7/28/20.
//

import Foundation
import Virtualization

class VirtualSystem: NSObject, VZVirtualMachineDelegate {
  let command: VirtualCommandRun
  var machine: VZVirtualMachine?

  init(command: VirtualCommandRun) {
    self.command = command
  }

  func guestDidStop(_: VZVirtualMachine) {
    NSLog("Virtual Machine Stopped")
  }

  func virtualMachine(_: VZVirtualMachine, didStopWithError error: Error) {
    NSLog("Virtual Machine Stopped: \(String(describing: error))")
  }

  func start() throws {
    let bootloader = VZLinuxBootLoader(kernelURL: URL(fileURLWithPath: command.kernel).absoluteURL)
    if !command.ramdisk.isEmpty {
      bootloader.initialRamdiskURL = URL(fileURLWithPath: command.ramdisk).absoluteURL
    }

    if !command.cmdline.isEmpty {
      bootloader.commandLine = command.cmdline
    }

    let entropy = VZVirtioEntropyDeviceConfiguration()
    let memoryBalloon = VZVirtioTraditionalMemoryBalloonDeviceConfiguration()

    var storage: [VZStorageDeviceConfiguration] = []
    if !command.disk.isEmpty {
      for disk in command.disk {
        let blockAttachment = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: disk).absoluteURL, readOnly: false)
        let blockDevice = VZVirtioBlockDeviceConfiguration(attachment: blockAttachment)
        storage.append(blockDevice)
      }
    }

    var network: [VZVirtioNetworkDeviceConfiguration] = []

    if command.network {
      let networkDevice = VZVirtioNetworkDeviceConfiguration()
      if !command.macaddr.isEmpty {
        if let macAddress = VZMACAddress(string: command.macaddr) {
          networkDevice.macAddress = macAddress
        } else {
          NSLog("Ignoring MAC Address: was not in acceptable format e.g. 01:23:45:ab:cd:ef")
        }
      }
      networkDevice.attachment = VZNATNetworkDeviceAttachment()
      network.append(networkDevice)
    }

    let serial = VZVirtioConsoleDeviceSerialPortConfiguration()

    serial.attachment = VZFileHandleSerialPortAttachment(
      fileHandleForReading: FileHandle.standardInput,
      fileHandleForWriting: FileHandle.standardOutput
    )

    let config = VZVirtualMachineConfiguration()
    config.bootLoader = bootloader
    config.cpuCount = command.processors
    config.memorySize = UInt64(command.memory * 1024 * 1024)
    config.entropyDevices = [entropy]
    config.memoryBalloonDevices = [memoryBalloon]
    config.serialPorts = [serial]
    config.storageDevices = storage
    config.networkDevices = network

    try config.validate()
    let vm = VZVirtualMachine(configuration: config)
    vm.delegate = self
    machine = vm

    vm.start { result in
      switch result {
      case .success:
        NSLog("Virtual Machine Started")
      case let .failure(error):
        NSLog("Virtual Machine Failure: \(error)")
      }
    }
  }

  func stateToString() -> String {
    guard let vm = machine else {
      return "Unknown"
    }

    switch vm.state {
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

  func stop() throws {
    if let vm = machine {
      try vm.requestStop()
    }
  }
}
