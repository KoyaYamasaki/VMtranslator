//
//  CodeWriter.swift
//  VMtranslator
//
//  Created by 山崎宏哉 on 2021/12/10.
//  Copyright © 2021 山崎宏哉. All rights reserved.
//

import Foundation

class CodeWriter {

    private var fileHandle: FileHandle

    private var stackBasePointer: Int = 256
    private var compOpCount: Int = 0
    private var callCount: Int = 0
    private var tempFunctionName = "returnAddress_0"

    private var classStaticVarAllocDict: [String: Int] = [:]
    private var currentClass = "Sys"
    private var currentClassStaticCount = 0
    private var baseStaticAddress = 16

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

    func writeInit() {
        writeCommand("@\(stackBasePointer)")
        writeCommand("D=A")
        writeCommand("@SP")
        writeCommand("M=D")
        writeCall(command: "Sys.init", numArgs: 0)
    }

    func writeArithmetic(command: String) {
        popStackValueToD()

        switch command {
        case "add":
            binaryOperation(operation: "M=M+D")
        case "sub":
            binaryOperation(operation: "M=M-D")
        case "neg":
            writeCommand("M=-D")
        case "eq":
            comparisonOperation(jmpType: "JEQ")
        case "gt":
            comparisonOperation(jmpType: "JGT")
        case "lt":
            comparisonOperation(jmpType: "JLT")
        case "and":
            binaryOperation(operation: "M=M&D")
        case "or":
            binaryOperation(operation: "M=M|D")
        case "not":
            writeCommand("M=!D")
        default:
            fatalError("Unknown arithmetic command was input.")
        }

        writeCommand("@SP")
        writeCommand("M=M+1")
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
            popStackValueToD()
            if segment != "static" {
                writeCommand("M=0")
            }

            // place the value on the target address.
            writeCommand("@\(segment.correspondingSymbol(index, staticAddress: baseStaticAddress))")
            if segment != "temp" && segment != "pointer" && segment != "static" {
                writeCommand("A=M")
            }
            writeCommand("M=D")
        default:
            fatalError("commandType is invalid in writePushPop function.")
        }

        // Reset address pointer.
        setSegmentAddress(segment: segment, index: index, forward: false)
    }

    func writeLabel(command: String) {
        writeCommand("(\(command))")
    }

    func writeIf(command: String) {
        popStackValueToD()
        writeCommand("@\(command)")
        writeCommand("D;JNE")
    }

    func writeGoto(command: String) {
        writeCommand("@\(command)")
        writeCommand("0;JMP")
    }

    func writeFunction(command: String, numLocals: Int) {
        writeCommand("(\(command))")
        for _ in 0..<numLocals {
            writeCommand("@SP")
            writeCommand("A=M")
            writeCommand("M=0")
            writeCommand("@SP")
            writeCommand("M=M+1")
        }
    }

    func writeCall(command: String, numArgs: Int) {
        self.callCount += 1
        self.tempFunctionName = "returnAddress_\(self.callCount)"

        // push return_address
        writeCommand("@\(self.tempFunctionName)")
        writeCommand("D=A")
        writeCommand("@SP")
        writeCommand("A=M")
        writeCommand("M=D")
        writeCommand("@SP")
        writeCommand("M=M+1")

        setSegmentForCall(segment: "LCL")
        setSegmentForCall(segment: "ARG")
        setSegmentForCall(segment: "THIS")
        setSegmentForCall(segment: "THAT")

        // ARG = SP-n-5
        writeCommand("@SP")
        writeCommand("D=M")
        writeCommand("@ARG")
        writeCommand("M=D")
        writeCommand("@\(numArgs)")
        writeCommand("D=A")
        writeCommand("@5")
        writeCommand("D=D+A")
        writeCommand("@ARG")
        writeCommand("M=M-D")

        // LCL = SP
        writeCommand("@SP")
        writeCommand("D=M")
        writeCommand("@LCL")
        writeCommand("M=D")

        writeCommand("@\(command)")
        writeCommand("0;JMP")

        writeCommand("(\(self.tempFunctionName))")
    }

    func writeReturn() {

        // FRAME = LCL
        writeCommand("@LCL")
        writeCommand("D=M")
        writeCommand("@R13")
        writeCommand("M=D")

        // RET = *(FRAME - 5)
        writeCommand("@R13")
        writeCommand("D=M")
        writeCommand("@5")
        writeCommand("D=D-A")
        writeCommand("@R14")
        writeCommand("M=D")
        writeCommand("@R14")
        writeCommand("A=M")
        writeCommand("D=M")
        writeCommand("@R14")
        writeCommand("M=D")

        // *ARG = pop()
        popStackValueToD()
        writeCommand("@ARG")
        writeCommand("A=M")
        writeCommand("M=D")

        // SP = ARG + 1
        writeCommand("@ARG")
        writeCommand("D=M")
        writeCommand("@SP")
        writeCommand("M=D+1")

        // THAT = *(FRAME - 1)
        setSegmentForReturn(segment: "THAT")
        // THIS = *(FRAME - 2)
        setSegmentForReturn(segment: "THIS")
        // ARG = *(FRAME - 3)
        setSegmentForReturn(segment: "ARG")
        // LCL = *(FRAME - 4)
        setSegmentForReturn(segment: "LCL")

        writeCommand("@R14")
        writeCommand("A=M")
        writeCommand("0;JMP")
    }

    private func popStackValueToD() {
        writeCommand("@SP")
        writeCommand("M=M-1")
        writeCommand("@SP")
        writeCommand("A=M")
        writeCommand("D=M")
    }

    private func comparisonOperation(jmpType: String) {
        compOpCount += 1
        writeCommand("@SP")
        writeCommand("M=M-1")
        writeCommand("@SP")
        writeCommand("A=M")
        writeCommand("D=M-D")
        writeCommand("@COMPTRUE_\(compOpCount)")
        writeCommand("D;\(jmpType)")
        writeCommand("@SP")
        writeCommand("A=M")
        writeCommand("M=0")
        writeCommand("@ENDCOMP_\(compOpCount)")
        writeCommand("0;JMP")
        writeCommand("(COMPTRUE_\(compOpCount))")
        writeCommand("@SP")
        writeCommand("A=M")
        writeCommand("M=-1")
        writeCommand("(ENDCOMP_\(compOpCount))")
    }

    private func binaryOperation(operation: String) {
        writeCommand("@SP")
        writeCommand("M=M-1")
        writeCommand("@SP")
        writeCommand("A=M")
        writeCommand(operation)
    }

    private func setSegmentForCall(segment: String) {
        writeCommand("@\(segment)")
        writeCommand("D=M")
        writeCommand("@SP")
        writeCommand("A=M")
        writeCommand("M=D")
        writeCommand("@SP")
        writeCommand("M=M+1")
    }

    private func setSegmentForReturn(segment: String) {
        writeCommand("@R13")
        writeCommand("M=M-1")
        writeCommand("@R13")
        writeCommand("A=M")
        writeCommand("D=M")
        writeCommand("@\(segment)")
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
            writeCommand("@\(segment.correspondingSymbol(index, staticAddress: baseStaticAddress))")
            writeCommand("D=M")
        case "constant":
            writeCommand("@\(index)")
            writeCommand("D=A")
        default:
            fatalError("Invalid segment was intput.")
        }
    }

    func countupStaticVariables(index: Int) {
        let usingSpace = index + 1
        if classStaticVarAllocDict[currentClass] != nil {
            if currentClassStaticCount < usingSpace {
                currentClassStaticCount = usingSpace
            }
        }
    }
    
    func setCurrentClass(className: String) {
        print("check class :\(className)")
        guard currentClass != className else {
            return
        }

        currentClass = className
        if classStaticVarAllocDict[className] == nil {
            print("new class added : \(currentClass)")
            baseStaticAddress = baseStaticAddress + currentClassStaticCount
            classStaticVarAllocDict[className] = baseStaticAddress
            print("base static address : \(baseStaticAddress)")
            currentClassStaticCount = 0
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
