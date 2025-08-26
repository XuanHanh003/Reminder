//
//  ReminderObject.swift
//  ReminderApp
//
//  Created by ikame on 8/26/25.
//

import Foundation
import RealmSwift

class ReminderObject: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var title: String = ""
    @Persisted var note: String?
    @Persisted var dueDate: Date?
    @Persisted var tag: String?
    @Persisted var isDone: Bool = false
    @Persisted var createdAt: Date = Date()
    @Persisted var updatedAt: Date = Date()
}
