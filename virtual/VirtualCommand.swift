//
//  VirtualCommand.swift
//  virtual
//
//  Created by Kenneth Endfinger on 7/28/20.
//

import ArgumentParser
import Foundation
import Virtualization

struct VirtualCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "virtual",
    abstract: "Linux Virtual Machines for macOS",
    subcommands: [
      VirtualCommandRun.self
    ],
    defaultSubcommand: VirtualCommandRun.self
  )

  @OptionGroup()
  var versionOptions: VirtualVersionOptions
}
