//
//  VirtualVersionOptions.swift
//  virtual
//
//  Created by Kenneth Endfinger on 11/27/20.
//

import ArgumentParser
import Cocoa

struct VirtualVersionOptions: ParsableArguments {
  @Flag(name: .long, help: "Show the Tool Version")
  var version: Bool = false

  func validate() throws {
    if version {
      let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String?

      if let versionAsString = bundleVersion {
        print("\(versionAsString)")
      } else {
        print("unknown")
      }
      throw ExitCode.success
    }
  }
}
