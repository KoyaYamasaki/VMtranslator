//
//  Extentions.swift
//  VMtranslator
//
//  Created by 山崎宏哉 on 2021/12/14.
//  Copyright © 2021 山崎宏哉. All rights reserved.
//

import Foundation
 
extension String {
    func correspondingSymbol(_ index: Int = 0, staticAddress: Int = 0) -> String {
        switch self {
        case "local":
            return "LCL"
        case "argument":
            return "ARG"
        case "this":
            return "THIS"
        case "that":
            return "THAT"
        case "temp":
            let tempAddress = index + 5
            return "R\(tempAddress)"
        case "pointer":
            let pointerAddress = index + 3
            return "R\(pointerAddress)"
        case "static":
            let staticAddress = index + staticAddress
            return "\(staticAddress)"
        default:
            fatalError("No correspondingSymbol was found")
        }
    }
}
