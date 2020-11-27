//
//  VirtualVersionOptions.swift
//  virtual
//
//  Created by Kenneth Endfinger on 11/27/20.
//

import ArgumentParser

struct VirtualVersionOptions: ParsableArguments {
  @Flag(name: .long, help: "Show the Tool Version")
  var version: Bool = false

  func validate() throws {
    if version {
      print(virtualToolVersion)
      throw ExitCode.success
    }
  }
}
