//
//  ModelConstants.swift
//  FirebaseWorkshop
//
//  Created by Romans Karpelcevs on 11/08/16.
//  Copyright © 2016 GDG. All rights reserved.
//

import Foundation

typealias UsersDictionary = [String: [String: AnyObject]]

struct Collection {
    static let Backlog = "backlog"
    static let Sprint = "sprint"
    static let InProgress = "in_progress"
    static let Done = "done"

    static let all = [Backlog, Sprint, InProgress, Done]
    static let titles = all.map { CollectionTitleMap[$0]! }
}

struct ItemKey {
    static let Title = "title"
    static let Assignee = "assignee"
    static let Collection = "collection"
    static let Attachment = "attachment"
}

struct UserKey {
    static let Email = "email"
    static let Karma = "karma"
    static let Avatar = "avatar"
}

let CollectionTitleMap = [Collection.Backlog: "Backlog",
                          Collection.Sprint: "Sprint",
                          Collection.InProgress: "In Progress",
                          Collection.Done: "Done"]

let MockListModel: [[String: String]] = [
    [ItemKey.Title: "Title 1", ItemKey.Assignee: "user1", ItemKey.Collection: Collection.Backlog],
    [ItemKey.Title: "Title 2", ItemKey.Assignee: "user1", ItemKey.Collection: Collection.Backlog],
    [ItemKey.Title: "Title 3", ItemKey.Assignee: "user2", ItemKey.Collection: Collection.Sprint],
    [ItemKey.Title: "Title 4", ItemKey.Assignee: "user2", ItemKey.Collection: Collection.Sprint],
    [ItemKey.Title: "Title 5", ItemKey.Assignee: "user3", ItemKey.Collection: Collection.Done],
    [ItemKey.Title: "Title 6", ItemKey.Assignee: "user3", ItemKey.Collection: Collection.Done],
    [ItemKey.Title: "Title 7", ItemKey.Assignee: "user3", ItemKey.Collection: Collection.Done],
]

let MockUserModel: UsersDictionary = [
    "user1": [UserKey.Email: "user1@gmail.com", UserKey.Karma: 0, UserKey.Avatar: "http://placekitten.com/160/160"],
    "user2": [UserKey.Email: "user2@gmail.com", UserKey.Karma: -1, UserKey.Avatar: ""],
    "user3": [UserKey.Email: "user3@gmail.com", UserKey.Karma: 100, UserKey.Avatar: ""],
]
