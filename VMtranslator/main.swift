//
//  main.swift
//  VMtranslator
//
//  Created by 山崎宏哉 on 2021/12/09.
//  Copyright © 2021 山崎宏哉. All rights reserved.
//

import Foundation

class VMtranslator {
    static var parser: Parser!
    static var codeWriter: CodeWriter!

    static func main() {
        let arguments = ProcessInfo().arguments
        let currentPath = FileManager.default.currentDirectoryPath

        guard arguments.count > 1 else {
            fatalError("target .vm file is not specified.")
        }

//        let fileUrl = currentPath + "/" + arguments[1]
        let url = URL(fileURLWithPath: arguments[1])
        let fileName = url.lastPathComponent

        guard fileName.hasSuffix(".vm") else {
            fatalError("Selected file is not .vm format")
        }

        let outputFile = fileName.replacingOccurrences(of: "vm", with: "asm")
        parser = Parser(fileURLStr: arguments[1])
        codeWriter = CodeWriter(inputFile: url, outputFile: outputFile)
        codeWriter.setup()
        start()
    }

    static func start() {
        startParse()
    }

    static func startParse() {
        var line = 1

        while parser.hasMoreCommands() {
            parser.advance()
            print("LINE = \(line)")
            print("\(parser.commandType.rawValue) : \(parser.currentCommand)")
            switch parser.commandType {
            case .C_ARITHMETIC:
                codeWriter.writeArithmetic(command: parser.arg1())
            case .C_PUSH, .C_POP:
                codeWriter.writePushPop(commandType: parser.commandType, segment: parser.arg1(), index: Int(parser.arg2())!)
            case .C_LABEL:
                codeWriter.writeLabel(command: parser.arg1())
            case .C_GOTO:
                codeWriter.writeGoto(command: parser.arg1())
            case .C_IF:
                codeWriter.writeIf(command: parser.arg1())
            default:
                print("default")
            }

            print("=========================")
            line += 1
        }
        codeWriter.close()
    }
}

VMtranslator.main()
