//
//  Created by ktiays on 2024/11/12.
//  Copyright (c) 2024 ktiays. All rights reserved.
// 

import Foundation

@propertyWrapper
struct Incrementable<T> where T: FixedWidthInteger {
    
    private var value: T
    
    var wrappedValue: T {
        mutating get {
            defer {
                value &+= 1
            }
            return value
        }
    }
    
    init(wrappedValue: T) {
        self.value = wrappedValue
    }
}
