//
//  Parser.swift
//  VMtranslator
//
//  Created by 山崎宏哉 on 2021/12/09.
//  Copyright © 2021 山崎宏哉. All rights reserved.
//

import Foundation

class Parser {

    var currentCommand = ""
    var commandSeparateByArgs: [String] = []

    private var position: Int = -1
    private var commandByLine: [String] = []

    init(fileURL: URL) {

        guard let fileContents = try? String(contentsOf: fileURL) else {
            fatalError("File could not be read.")
        }

        let separatedByLine = fileContents.components(separatedBy: "\n")

        // Remove line break lines.
        let removeEmptySpace = separatedByLine.filter({ $0 != "\r" && !$0.isEmpty })

        // Remove comment lines.
        let removeComment = removeEmptySpace.filter {
            !$0.hasPrefix("//")
        }

        // Remove Same line comment
        commandByLine = removeComment.map({
            if let commentIndex = $0.range(of: "//") {
                return String($0[..<commentIndex.lowerBound])
            } else { return $0 }
        })

        // Remove spaces
        commandByLine = commandByLine.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })

        for aOrder in commandByLine {
            print(aOrder)
        }
    }

    func hasMoreCommands() -> Bool {
        return position + 1 != commandByLine.count
    }

    func advance() {
        
        if hasMoreCommands() {
            position += 1
            currentCommand = commandByLine[position]
            commandSeparateByArgs = currentCommand.components(separatedBy: " ")
        }
    }

    var commandType: CommandType {
        switch commandSeparateByArgs[0] {
        case "push":
            return .C_PUSH
        case "pop":
            return .C_POP
        case "label":
            return .C_LABEL
        case "if-goto":
            return .C_IF
        case "goto":
            return .C_GOTO
        case "function":
            return .C_FUNCTION
        case "call":
            return .C_CALL
        case "return":
            return .C_RETURN
        default:
            if commandSeparateByArgs.count == 1 {
                return .C_ARITHMETIC
            } else {
                return .UNKNOWN
            }
        }
    }
    
    func arg1() -> String {
        guard position != -1 else {
            fatalError("Invalid to call this func before starting parse")
        }

        if commandType == .C_ARITHMETIC {
            return commandSeparateByArgs[0]
        } else {
            return commandSeparateByArgs[1]
        }
    }

    func arg2() -> String  {
        guard commandType == .C_PUSH ||
            commandType == .C_POP ||
            commandType == .C_FUNCTION ||
            commandType == .C_CALL else {
            fatalError("Invalid to call thic func while currenCommad is not C_PUSH, C_POP, C_FUNCTION or C_CALL")
        }

        return commandSeparateByArgs[2]
    }

}
