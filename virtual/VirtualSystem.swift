//
//  VirtualSystem.swift
//  virtual
//
//  Created by Kenneth Endfinger on 7/28/20.
//

import Foundation
import Virtualization

class VirtualSystem: NSObject, VZVirtualMachineDelegate {
  let command: VirtualCommand

  var machine: VZVirtualMachine?

  init(command: VirtualCommand) {
    self.command = command
  }

  func guestDidStop(_: VZVirtualMachine) {
    NSLog("Guest Stop.")
  }

  func virtualMachine(_: VZVirtualMachine, didStopWithError error: Error) {
    NSLog("Guest Stopped with error: \(String(describing: error))")
  }

  func start(completionHandler _: (Result<Void, Error>) -> Void) throws {
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

    let networkDevice = VZVirtioNetworkDeviceConfiguration()
    networkDevice.attachment = VZNATNetworkDeviceAttachment()

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
    config.networkDevices = [networkDevice]

    try config.validate()
    let vm = VZVirtualMachine(configuration: config)
    machine = vm

    let semaphore = DispatchSemaphore(value: 0)
    vm.start { result in
      switch result {
      case .success:
        exit(0)
      case .failure:
        NSLog("Boot Failure.")
      }
    }
    semaphore.wait()
  }

  func stop() throws {
    if machine != nil {
      try machine!.requestStop()
    }
  }
}
