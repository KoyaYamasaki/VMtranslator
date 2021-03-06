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
        if !url.isDirectory {
            let fileName = url.lastPathComponent

            guard fileName.hasSuffix(".vm") else {
                fatalError("Selected file is not .vm format")
            }

            let outputFile = fileName.replacingOccurrences(of: "vm", with: "asm")
            let outputFileDir = url.deletingLastPathComponent().appendingPathComponent(outputFile)
            parser = Parser(fileURL: url)
            codeWriter = CodeWriter(outputFileDir: outputFileDir)
            start()
        } else {
            do {
                // Get the directory contents urls (including subfolders urls)
                let directoryContents =
                    try FileManager
                        .default
                        .contentsOfDirectory(
                            at: url,
                            includingPropertiesForKeys: nil
                    )
                let vmFileUrls = directoryContents.filter{ $0.pathExtension == "vm" }
                let outputFile = url.lastPathComponent.appending(".asm")

                guard vmFileUrls.count != 0 else {
                    fatalError("There has not contained .vm format file")
                }

                let outputFileDir = vmFileUrls.first!.deletingLastPathComponent().appendingPathComponent(outputFile)
                codeWriter = CodeWriter(outputFileDir: outputFileDir)

                for vmUrl in vmFileUrls {
                    parser = Parser(fileURL: vmUrl)
                    start()
                }

            } catch {
                fatalError("Unable to get list of files inside the directory")
            }
        }
    }

    static func start() {
        codeWriter.writeInit()
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
                guard let segIndex = Int(parser.arg2()) else {
                    fatalError("Unable to cast parser.arg2() to Int")
                }

                if parser.arg1() == "static" {
                    codeWriter.countupStaticVariables(index: segIndex)
                }

                codeWriter.writePushPop(commandType: parser.commandType, segment: parser.arg1(), index: segIndex)
            case .C_LABEL:
                codeWriter.writeLabel(command: parser.arg1())
            case .C_GOTO:
                codeWriter.writeGoto(command: parser.arg1())
            case .C_IF:
                codeWriter.writeIf(command: parser.arg1())
            case .C_FUNCTION:
                guard let segIndex = Int(parser.arg2()) else {
                    fatalError("Unable to cast parser.arg2() to Int")
                }

                let className = parser.arg1().components(separatedBy: ".").first
                guard className != nil else {
                    fatalError("Unable to get class name from parser.arg1()")
                }

                codeWriter.setCurrentClass(className: className!)
                codeWriter.writeFunction(command: parser.arg1(), numLocals: segIndex)
            case .C_CALL:
                guard let segIndex = Int(parser.arg2()) else {
                    fatalError("Unable to cast parser.arg2() to Int")
                }

                codeWriter.writeCall(command: parser.arg1(), numArgs: segIndex)
            case .C_RETURN:
                codeWriter.writeReturn()
            default:
                fatalError("Parser.commandType is unknown. Unable to procceed.")
            }

            print("=========================")
            line += 1
        }
        codeWriter.close()
    }
}

VMtranslator.main()
