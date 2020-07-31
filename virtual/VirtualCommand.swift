//
//  VirtualCommand.swift
//  virtual
//
//  Created by Kenneth Endfinger on 7/28/20.
//

import ArgumentParser
import Foundation

struct VirtualCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "virtual",
    abstract: "Linux Virtual Machines for macOS"
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

  mutating func run() throws {
    enableRawMode(fileHandle: FileHandle.standardInput)
    
    let system = VirtualSystem(command: self)
    let semaphore = DispatchSemaphore(value: 0)
    do {
      try system.start { result in
        switch result {
        case .failure:
          NSLog("Failed to start VM.")
        case .success:
          break
        }
        semaphore.signal()
      }
    } catch {
      NSLog("ERROR: \(error)")
    }
    semaphore.wait()
  }
}
