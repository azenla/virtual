//
//  VirtualCommandRun.swift
//  virtual
//
//  Created by Kenneth Endfinger on 11/27/20.
//

import ArgumentParser
import Foundation
import Virtualization
import VirtualCore

struct VirtualCommandRun: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "run",
    abstract: "Run a Linux Virtual Machine"
  )

  @Option(name: .shortAndLong, help: "Kernel Path")
  var kernel: String

  @Option(name: .shortAndLong, help: "Initial Ramdisk")
  var ramdisk: String = ""

  @Option(name: .shortAndLong, help: "Disk Image")
  var disk: [String] = []

  @Option(name: .shortAndLong, help: "Kernel Command Line")
  var cmdline: String = ""

  @Option(name: .shortAndLong, help: "CPU Core Count")
  var processors: Int = 4

  @Option(name: .shortAndLong, help: "Machine Memory")
  var memory: Int = 2048

  @Flag(name: .shortAndLong, help: "Enable NAT Networking")
  var network: Bool = false

  // if not specified, will generate at random
  @Option(name: [.customShort("a"), .long], help: "MAC Address")
  var macaddr: String = ""

  @Flag(name: .long, help: "Show Version Information")
  var version: Bool = false

  mutating func run() throws {
    enableRawMode(fileHandle: FileHandle.standardInput)

    var profile = VirtualProfile(
      cores: UInt64(processors),
      memory: UInt64(memory),
      boot: VirtualBootProfile(kernelFileURL: try VirtualCommandRun.filePathAsURLIfNotEmpty(kernel)!)
    )

    profile.boot.ramdiskFileURL = try VirtualCommandRun.filePathAsURLIfNotEmpty(ramdisk)
    if !cmdline.isEmpty {
      profile.boot.kernelCommandLine = cmdline
    }

    if network {
      var networkProfile = VirtualNetworkProfile(type: .NAT)
      if !macaddr.isEmpty {
        networkProfile.macAddress = macaddr
      }
      profile.networks.append(networkProfile)
    }

    for diskFilePath in disk {
      let fileURL = try VirtualCommandRun.filePathAsURLIfNotEmpty(diskFilePath)
      if fileURL == nil {
        continue
      }
      let diskProfile = VirtualDiskProfile(fileURL!)
      profile.disks.append(diskProfile)
    }

    let vm = try VirtualMachine.create(profile)
    vm.start()

    let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
    timer.schedule(deadline: .now(), repeating: .milliseconds(100))

    var lastMachineState: VZVirtualMachine.State = .stopped
    timer.setEventHandler {
      let currentState = vm.machine.state
      if currentState != lastMachineState {
        NSLog("Virtual Machine State: \(vm.stateAsString())")
        lastMachineState = currentState
      }

      if currentState == .error {
        VirtualCommand.exit(withError: ExitCode.failure)
      } else if currentState == .stopped {
        VirtualCommand.exit(withError: ExitCode.success)
      }
    }
    timer.resume()

    dispatchMain()
  }

  static func filePathAsURLIfNotEmpty(_ path: String) throws -> URL? {
    if path.isEmpty {
      return nil
    }

    let url = URL(fileURLWithPath: path)
    if FileManager.default.fileExists(atPath: url.absoluteString) {
      NSLog("File Exists: \(url.absoluteString)")
      return url
    } else {
      NSLog("[ERROR] File does not exist: \(url.absoluteString)")
      throw ExitCode.failure
    }
  }
}
