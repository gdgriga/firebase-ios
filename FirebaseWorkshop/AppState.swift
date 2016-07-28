//
//  AppState.swift
//  FirebaseWorkshop
//
//  Created by Romans Karpelcevs on 17/08/16.
//  Copyright © 2016 GDG. All rights reserved.
//

import UIKit

class AppState: NSObject {
    static let sharedInstance = AppState()

    var ownUserID: String? = "user1"
}
