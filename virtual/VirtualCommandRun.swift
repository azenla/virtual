//
//  VirtualCommandRun.swift
//  virtual
//
//  Created by Kenneth Endfinger on 11/27/20.
//

import ArgumentParser
import Foundation
import Virtualization

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

  @Flag(name: .long, help: "Show Version Information")
  var version: Bool = false

  mutating func run() throws {
    if version {
      print("virtual version \(virtualToolVersion)")
      VirtualCommand.exit()
    }

    enableRawMode(fileHandle: FileHandle.standardInput)

    let system = VirtualSystem(command: self)
    do {
      try system.start()

      var lastState: VZVirtualMachine.State = .stopped
      while system.machine != nil {
        let currentState = system.machine!.state
        if currentState != lastState {
          NSLog("Virtual Machine State: \(system.stateToString())")
          lastState = currentState
        }

        if currentState == .error {
          VirtualCommand.exit()
        }

        sleep(1)
      }
    } catch {
      NSLog("\(error)")
    }
  }
}
