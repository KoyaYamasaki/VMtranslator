//
//  CodeWriter.swift
//  VMtranslator
//
//  Created by 山崎宏哉 on 2021/12/10.
//  Copyright © 2021 山崎宏哉. All rights reserved.
//

import Foundation

class CodeWriter {

    var fileHandle: FileHandle

//    private var stackBasePointer: Int = 256
    private var funcIndex: Int = 0
    private var numLocals: Int = 0

    init(outputFileDir: URL) {

        FileManager
            .default
            .createFile(
                atPath: outputFileDir.path,
                contents: "".data(using: .utf8),
                attributes: nil
        )

        print("outputFileDir: \(outputFileDir)")
        self.fileHandle = FileHandle(forWritingAtPath: outputFileDir.path)!
    }

    func setup() {
//        writeCommand("@\(stackBasePointer)")
//        writeCommand("D=A")
//        writeCommand("@SP")
//        writeCommand("M=D")
    }

    private func backStackPointer() {
        writeCommand("@SP")
        writeCommand("M=M-1")
        writeCommand("@SP")
        writeCommand("A=M")
    }

    private func compareCalc(jmpType: String) {
        writeCommand("D=M-D")
        writeCommand("@COMPTRUE_\(funcIndex)")
        writeCommand("D;\(jmpType)")
        writeCommand("@SP")
        writeCommand("A=M")
        writeCommand("M=0")
        writeCommand("@ENDCOMP_\(funcIndex)")
        writeCommand("0;JMP")
        writeCommand("(COMPTRUE_\(funcIndex))")
        writeCommand("@SP")
        writeCommand("A=M")
        writeCommand("M=-1")
        writeCommand("(ENDCOMP_\(funcIndex))")
    }

    func writeArithmetic(command: String) {
        backStackPointer()
        writeCommand("D=M")

        switch command {
        case "add":
            backStackPointer()
            writeCommand("M=M+D")
        case "sub":
            backStackPointer()
            writeCommand("M=M-D")
        case "neg":
            writeCommand("M=-D")
        case "eq":
            backStackPointer()
            compareCalc(jmpType: "JEQ")
        case "gt":
            backStackPointer()
            compareCalc(jmpType: "JGT")
        case "lt":
            backStackPointer()
            compareCalc(jmpType: "JLT")
        case "and":
            backStackPointer()
            writeCommand("M=M&D")
        case "or":
            backStackPointer()
            writeCommand("M=M|D")
        case "not":
            writeCommand("M=!D")
        default:
            fatalError("Unknown arithmetic command was input.")
        }

        writeCommand("@SP")
        writeCommand("M=M+1")
        funcIndex += 1
    }

    func writePushPop(commandType: CommandType, segment: String, index: Int) {

        switch commandType {
        case .C_PUSH:
            setSegmentAddress(segment: segment, index: index, forward: true)
            setSegmentAddressValueToD(segment: segment, index: index)
            writeCommand("@SP")
            writeCommand("A=M")
            writeCommand("M=D")
            writeCommand("@SP")
            writeCommand("M=M+1")
        case .C_POP:
            // Set target address.
            setSegmentAddress(segment: segment, index: index, forward: true)

            // get value from stack address and place 0 on that address.
            backStackPointer()
            writeCommand("D=M")
            if segment != "static" {
                writeCommand("M=0")
            }

            // place the value on the target address.
            writeCommand("@\(segment.correspondingSymbol(index))")
            if segment != "temp" && segment != "pointer" && segment != "static" {
                writeCommand("A=M")
            }
            writeCommand("M=D")
        default:
            print("default")
        }

        // Reset address pointer.
        setSegmentAddress(segment: segment, index: index, forward: false)
    }

    func writeLabel(command: String) {
        writeCommand("(\(command))")
    }

    func writeIf(command: String) {
        backStackPointer()
        writeCommand("D=M")
        writeCommand("@\(command)")
        writeCommand("D;JNE")
    }

    func writeGoto(command: String) {
        writeCommand("@\(command)")
        writeCommand("0;JMP")
    }

    func writeFunction(command: String, numLocals: Int) {
        self.numLocals = numLocals
        writeCommand("@\(numLocals)")
        writeCommand("D=A")
        writeCommand("@SP")
        writeCommand("M=M+D")
    }

    func writeCall(command: String, numArgs: Int) {
        print("call")
    }

    func writeReturn() {
        // TODO: Fix this later
        backStackPointer()
        writeCommand("D=M")
        writeCommand("@ARG")
        writeCommand("A=M")
        writeCommand("M=D")

        writeCommand("@ARG")
        writeCommand("D=M")
        writeCommand("@SP")
        writeCommand("M=D+1")
        writeCommand("@R13")
        writeCommand("M=D")


        // Point to the preserved RETURN address
        writeCommand("@2")
        writeCommand("D=A")
        writeCommand("@R13")
        writeCommand("M=M+D")
        writeCommand("@R13")
        writeCommand("A=M")
        writeCommand("D=M")
        writeCommand("@R14")
        writeCommand("M=D")

        // Point to the preserved LOCAL address
        writeCommand("@R13")
        writeCommand("M=M+1")
        writeCommand("@R13")
        writeCommand("A=M")
        writeCommand("D=M")
        writeCommand("@LCL")
        writeCommand("M=D")

        // Point to the preserved ARGUMENT address
        writeCommand("@R13")
        writeCommand("M=M+1")
        writeCommand("@R13")
        writeCommand("A=M")
        writeCommand("D=M")
        writeCommand("@ARG")
        writeCommand("M=D")

        // Point to the preserved THIS address
        writeCommand("@R13")
        writeCommand("M=M+1")
        writeCommand("@R13")
        writeCommand("A=M")
        writeCommand("D=M")
        writeCommand("@THIS")
        writeCommand("M=D")

        // Point to the preserved THAT address
        writeCommand("@R13")
        writeCommand("M=M+1")
        writeCommand("@R13")
        writeCommand("A=M")
        writeCommand("D=M")
        writeCommand("@THAT")
        writeCommand("M=D")

    }

    private func setSegmentAddress(segment: String, index: Int, forward: Bool) {

        switch segment {
        case "local", "argument", "this", "that":
            writeCommand("@\(segment.correspondingSymbol())")
            writeCommand("D=M")
            writeCommand("@\(index)")
            if forward {
                writeCommand("D=D+A")
            } else {
                writeCommand("D=D-A")
            }
            writeCommand("@\(segment.correspondingSymbol())")
            writeCommand("M=D")
        case "temp", "pointer", "constant", "static":
            // no need to set target address in advance.
            return
        default:
            fatalError("Invalid segment was intput.")
        }
    }

    private func setSegmentAddressValueToD(segment: String, index: Int) {
        switch segment {
        case "local", "argument", "this", "that":
             writeCommand("@\(segment.correspondingSymbol())")
             writeCommand("A=M")
             writeCommand("D=M")
        case "temp", "pointer", "static":
            writeCommand("@\(segment.correspondingSymbol(index))")
            writeCommand("D=M")
        case "constant":
            writeCommand("@\(index)")
            writeCommand("D=A")
        default:
            fatalError("Invalid segment was intput.")
        }
    }

    func close() {
//        writeCommand("@SP")
//        writeCommand("M=M+1")
//        writeCommand("@SP")
//        writeCommand("A=M")
//        writeCommand("M=0")
    }

    private func writeCommand(_ command: String) {
        self.fileHandle.write(command.data(using: .utf8)!)
        self.fileHandle.write("\n".data(using: .utf8)!)
    }
}
