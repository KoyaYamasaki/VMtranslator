//
//  CommandType.swift
//  VMtranslator
//
//  Created by 山崎宏哉 on 2021/12/10.
//  Copyright © 2021 山崎宏哉. All rights reserved.
//

import Foundation

enum CommandType: String {
    case C_ARITHMETIC = "C_ARITHMETIC"
    case C_PUSH = "C_PUSH"
    case C_POP = "C_POP"
    case C_LABEL = "C_LABEL"
    case C_GOTO = "C_GOTO"
    case C_IF = "C_IF"
    case C_FUNCTION = "C_FUNCTION"
    case C_RETURN = "C_RETURN"
    case C_CALL = "C_CALL"
    case UNKNOWN = "UNKNOWN"
}
