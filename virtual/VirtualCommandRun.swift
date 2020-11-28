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
    enableRawMode(fileHandle: FileHandle.standardInput)

    let system = VirtualSystem(command: self)
    do {
      try system.start()

      let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
      timer.schedule(deadline: .now(), repeating: .milliseconds(100))

      var lastMachineState: VZVirtualMachine.State = .stopped
      timer.setEventHandler {
        let currentState = system.machine!.state
        if currentState != lastMachineState {
          NSLog("Virtual Machine State: \(system.stateToString())")
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
    } catch {
      NSLog("\(error)")
    }
  }
}
