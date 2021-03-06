//
//  StringCharacteristicProfile.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/26/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class StringCharacteristicProfile : CharacteristicProfile {
    
    // PUBLIC
    public var encoding : NSStringEncoding = NSUTF8StringEncoding

    public override init(uuid:String, name:String, initializer:((characteristicProfile:StringCharacteristicProfile) -> ())? = nil) {
        super.init(uuid:uuid, name:name)
        if let runInitializer = initializer {
            runInitializer(characteristicProfile:self)
        }
    }
        
    public override func stringValues(data:NSData) -> [String:String]? {
        let value = NSString(data:data, encoding:self.encoding) as String
        return [self.name:value]
    }
    
    public override func anyValue(data:NSData) -> Any? {
        return NSString(data:data, encoding:self.encoding)
    }
    
    public override func dataFromStringValue(data:Dictionary<String, String>) -> NSData? {
        if let value = data[self.name] {
            return self.dataFromAnyValue(value)
        } else {
            return nil
        }
    }
    
    public override func dataFromAnyValue(object:Any) -> NSData? {
        if let value = object as? String {
            return value.dataUsingEncoding(self.encoding)
        } else {
            return nil
        }
    }
}
