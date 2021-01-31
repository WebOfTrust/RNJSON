import Foundation

@dynamicMemberLookup
public enum RNJSON: Hashable {
    case string(String)
    case number(NSNumber)
    case bool(Bool)
    case object([String: RNJSON])
    case array([RNJSON])
    case null
}

// MARK: - Errors
public extension RNJSON {
    enum Error: Swift.Error {
        case typeMismatch
    }
}

// MARK: - StringKey
private struct StringKey: CodingKey, Hashable, Comparable, CustomStringConvertible, ExpressibleByStringLiteral {
    public var description: String { stringValue }

    public let stringValue: String
    public init(_ string: String) { self.stringValue = string }
    public init?(stringValue: String) { self.init(stringValue) }
    public var intValue: Int? { nil }
    public init?(intValue: Int) { nil }

    public static func < (lhs: StringKey, rhs: StringKey) -> Bool { lhs.stringValue < rhs.stringValue }

    public init(stringLiteral value: String) { self.init(value) }
}

// MARK: - String
public extension RNJSON {
    var isString: Bool {
        if case .string = self { return true } else { return false }
    }

    func stringValue() throws -> String {
        guard case .string(let value) = self else { throw Error.typeMismatch }
        return value
    }

    init(_ value: String) {
        self = .string(value)
    }
}

extension RNJSON: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

// MARK: - Number
public extension RNJSON {
    var isNumber: Bool {
        if case .number = self { return true } else { return false }
    }

    func numberValue() throws -> NSNumber {
        guard case .number(let value) = self else { throw Error.typeMismatch }
        return value
    }

    func doubleValue() throws -> Double { try numberValue().doubleValue }
    func intValue() throws -> Int { try numberValue().intValue }
    func decimalValue() throws -> Decimal { try numberValue().decimalValue }

    init(_ value: NSNumber) { self = .number(value) }

    init(_ value: Int8)   { self.init(value as NSNumber) }
    init(_ value: Double) { self.init(value as NSNumber) }
    init(_ value: Float)  { self.init(value as NSNumber) }
    init(_ value: Int32)  { self.init(value as NSNumber) }
    init(_ value: Int)    { self.init(value as NSNumber) }
    init(_ value: Int64)  { self.init(value as NSNumber) }
    init(_ value: Int16)  { self.init(value as NSNumber) }
    init(_ value: UInt8)  { self.init(value as NSNumber) }
    init(_ value: UInt32) { self.init(value as NSNumber) }
    init(_ value: UInt)   { self.init(value as NSNumber) }
    init(_ value: UInt64) { self.init(value as NSNumber) }
    init(_ value: UInt16) { self.init(value as NSNumber) }
}

extension RNJSON: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public init(integerLiteral value: Int) { self.init(value) }
    public init(floatLiteral value: Double) { self.init(value) }
}

// MARK: - Bool
public extension RNJSON {
    var isBool: Bool {
        if case .bool = self { return true } else { return false }
    }

    func boolValue() throws -> Bool {
        guard case .bool(let value) = self else { throw Error.typeMismatch }
        return value
    }

    init(_ value: Bool) {
        self = .bool(value)
    }
}

// MARK: - Object
public extension RNJSON {
    var isObject: Bool {
        if case .object = self { return true } else { return false }
    }

    func objectValue() throws -> [String: RNJSON] {
        guard case .object(let value) = self else { throw Error.typeMismatch }
        return value
    }

    subscript(key: String) -> RNJSON? {
        try? objectValue()[key]
    }

    init(_ value: [String: RNJSON]) {
        self = .object(value)
    }
}

extension RNJSON: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, RNJSON)...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }
}

public typealias JSONObject = [String: RNJSON]

// MARK: - Array
public extension RNJSON {
    var isArray: Bool {
        if case .array = self { return true } else { return false }
    }

    func arrayValue() throws -> [RNJSON] {
        guard case .array(let value) = self else { throw Error.typeMismatch }
        return value
    }

    subscript(index: Int) -> RNJSON {
        guard let array = try? arrayValue(),
              array.indices.contains(index)
        else { return .null }

        return array[index]
    }

    init(_ value: [RNJSON]) {
        self = .array(value)
    }
}

extension RNJSON: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: RNJSON...) {
        self.init(elements)
    }
}

// MARK: - Null
public extension RNJSON {
    var isNull: Bool {
        if case .null = self { return true } else { return false }
    }

    init(_ value: NSNull) {
        self = .null
    }
}

//extension JSON: ExpressibleByNilLiteral {
//    public init(nilLiteral: Void) {
//        self.init(NSNull())
//    }
//}

// MARK: - Dynamic Member Lookup
public extension RNJSON {
    subscript(dynamicMember member: String) -> RNJSON {
        self[member] ?? .null
    }
}

// MARK: - Decodable
extension RNJSON: Decodable {
    public init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self) { self = .string(string) }

        else if let number = try? decoder.singleValueContainer().decode(Decimal.self) { self = .number(number as NSNumber) }

        else if let bool = try? decoder.singleValueContainer().decode(Bool.self) { self = .bool(bool) }

        else if let object = try? decoder.container(keyedBy: StringKey.self) {
            let pairs = try object.allKeys.map(\.stringValue).map { key in
                (key, try object.decode(RNJSON.self, forKey: StringKey(key)))
            }
            self = .object(Dictionary(uniqueKeysWithValues: pairs))
        }

        else if var array = try? decoder.unkeyedContainer() {
            var result: [RNJSON] = []
            while !array.isAtEnd {
                result.append(try array.decode(RNJSON.self))
            }
            self = .array(result)
        }

        else if let isNull = try? decoder.singleValueContainer().decodeNil(), isNull { self = .null }

        else { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [],
                                                                       debugDescription: "Unknown JSON type")) }
    }
}

// MARK: - Encodable
extension RNJSON: Encodable {
    public func encode(to encoder: Encoder) throws {
        switch self {

        case .string(let string):
            var container = encoder.singleValueContainer()
            try container.encode(string)

        case .number(let number):
            var container = encoder.singleValueContainer()
            try container.encode(number.decimalValue)

        case .bool(let bool):
            var container = encoder.singleValueContainer()
            try container.encode(bool)

        case .object(let object):
            var container = encoder.container(keyedBy: StringKey.self)
            for key in object.keys.sorted() {
                try container.encode(object[key], forKey: StringKey(key))
            }

        case .array(let array):
            var container = encoder.unkeyedContainer()
            for value in array {
                try container.encode(value)
            }

        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

// MARK: - CustomStringConvertible
extension RNJSON: CustomStringConvertible {
    public var description: String {
        switch self {
        case .string(let string): return "\"\(string)\""

        case .number(let number): return "\(number)"

        case .bool(let bool): return "\(bool)"

        case .object(let object):
            let keyValues = object
                .map { (key, value) in "\"\(key)\": \(value)" }
                .joined(separator: ",")
            return "{\(keyValues)}"

        case .array(let array): return "\(array)"

        case .null: return "null"
        }
    }
}

// MARK: - Any
public extension RNJSON {
    init(withAny value: Any) throws {
        switch value {
        case let json as RNJSON: self = json
        case let string as String: self = RNJSON(string)
        case let number as NSNumber: self = RNJSON(number)
        case let bool as Bool: self = RNJSON(bool)
        case let object as [String: Any]: self = RNJSON(try object.mapValues(RNJSON.init(withAny:)))
        case let array as [Any]: self = RNJSON(try array.map(RNJSON.init(withAny:)))
        case is NSNull: self = .null
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [],
                                                                          debugDescription: "Cannot encode value"))
        }
    }

    func anyDictionary() throws -> [String: Any] {
        try objectValue().mapValues(RNJSON.anyValue)
    }

    func anyArray() throws -> [Any] {
        try arrayValue().map(RNJSON.anyValue)
    }

    func anyValue() throws -> Any {
        switch self {
        case .string(let value): return value
        case .number(let value): return value
        case .bool(let value): return value
        case .object(let object): return object.mapValues(RNJSON.anyValue)
        case .array(let array): return array.map(RNJSON.anyValue)
        case .null: return NSNull()
        }
    }
}
