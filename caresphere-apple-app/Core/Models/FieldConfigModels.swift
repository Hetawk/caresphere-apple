//
//  FieldConfigModels.swift
//  CareSphere
//
//  Created on 11/21/25.
//

import Foundation

// MARK: - Field Types
enum FieldType: String, Codable {
    case text
    case email
    case phone
    case number
    case date
    case select
    case multiselect
    case checkbox
    case textarea
    case url
    case file
}

// MARK: - Entity Types
enum EntityType: String, Codable {
    case member
    case message
    case event
    case donation
    case volunteer
}

// MARK: - Field Configuration
struct FieldConfig: Codable, Identifiable {
    let id: String
    let organizationId: String
    let entityType: EntityType
    let fieldKey: String
    let fieldLabel: String
    let fieldType: FieldType
    let description: String?
    let placeholder: String?
    let options: [String]
    let validationRules: [String: AnyCodable]
    let isRequired: Bool
    let isVisible: Bool
    let isSearchable: Bool
    let displayOrder: Int
    let defaultValue: String?
    let groupName: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case entityType = "entity_type"
        case fieldKey = "field_key"
        case fieldLabel = "field_label"
        case fieldType = "field_type"
        case description
        case placeholder
        case options
        case validationRules = "validation_rules"
        case isRequired = "is_required"
        case isVisible = "is_visible"
        case isSearchable = "is_searchable"
        case displayOrder = "display_order"
        case defaultValue = "default_value"
        case groupName = "group_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Field Configuration Response
struct FieldConfigsResponse: Codable {
    let configs: [FieldConfig]
}

// MARK: - Entity Fields Response
struct EntityFieldsResponse: Codable {
    let configs: [FieldConfig]
    let values: [String: AnyCodable]
}

// MARK: - Field Configuration Create/Update
struct FieldConfigCreate: Codable {
    let entityType: EntityType
    let fieldKey: String
    let fieldLabel: String
    let fieldType: FieldType
    let description: String?
    let placeholder: String?
    let options: [String]
    let validationRules: [String: AnyCodable]
    let isRequired: Bool
    let isVisible: Bool
    let isSearchable: Bool
    let displayOrder: Int
    let defaultValue: String?
    let groupName: String?

    enum CodingKeys: String, CodingKey {
        case entityType = "entity_type"
        case fieldKey = "field_key"
        case fieldLabel = "field_label"
        case fieldType = "field_type"
        case description
        case placeholder
        case options
        case validationRules = "validation_rules"
        case isRequired = "is_required"
        case isVisible = "is_visible"
        case isSearchable = "is_searchable"
        case displayOrder = "display_order"
        case defaultValue = "default_value"
        case groupName = "group_name"
    }
}

struct FieldConfigUpdate: Codable {
    let fieldLabel: String?
    let fieldType: FieldType?
    let description: String?
    let placeholder: String?
    let options: [String]?
    let validationRules: [String: AnyCodable]?
    let isRequired: Bool?
    let isVisible: Bool?
    let isSearchable: Bool?
    let displayOrder: Int?
    let defaultValue: String?
    let groupName: String?

    enum CodingKeys: String, CodingKey {
        case fieldLabel = "field_label"
        case fieldType = "field_type"
        case description
        case placeholder
        case options
        case validationRules = "validation_rules"
        case isRequired = "is_required"
        case isVisible = "is_visible"
        case isSearchable = "is_searchable"
        case displayOrder = "display_order"
        case defaultValue = "default_value"
        case groupName = "group_name"
    }
}

// MARK: - Bulk Field Values Update
struct BulkFieldValuesUpdate: Codable {
    let entityType: EntityType
    let entityId: String
    let values: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case entityType = "entity_type"
        case entityId = "entity_id"
        case values
    }
}

// MARK: - AnyCodable Helper
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if value is NSNull {
            try container.encodeNil()
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dictionary = value as? [String: Any] {
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Grouped Fields
struct GroupedFieldConfigs {
    let groupName: String?
    let configs: [FieldConfig]
}

extension Array where Element == FieldConfig {
    /// Group field configurations by their group name
    func grouped() -> [GroupedFieldConfigs] {
        let grouped = Dictionary(grouping: self) { $0.groupName }
        return grouped.map {
            GroupedFieldConfigs(
                groupName: $0.key, configs: $0.value.sorted { $0.displayOrder < $1.displayOrder })
        }
        .sorted { (lhs, rhs) in
            // Sort groups: named groups first (alphabetically), then ungrouped
            switch (lhs.groupName, rhs.groupName) {
            case (nil, nil): return false
            case (nil, _): return false
            case (_, nil): return true
            case (let l?, let r?): return l < r
            }
        }
    }
}
