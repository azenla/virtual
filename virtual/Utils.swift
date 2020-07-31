//
//  Utils.swift
//  virtual
//
//  Created by Kenneth Endfinger on 7/29/20.
//

import Foundation

func initMemoryStruct<S>() -> S {
  let pointer = UnsafeMutablePointer<S>.allocate(capacity: 1)
  let memory = pointer.pointee
  pointer.deallocate()
  return memory
}

func enableRawMode(fileHandle: FileHandle) {
  var raw: termios = initMemoryStruct()
  tcgetattr(fileHandle.fileDescriptor, &raw)

  raw.c_lflag &= ~UInt(ECHO | ICANON)
  tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &raw)
}
