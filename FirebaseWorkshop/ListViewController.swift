//
//  ListViewController.swift
//  FirebaseWorkshop
//
//  Created by Romans Karpelcevs on 28/07/16.
//  Copyright © 2016 GDG. All rights reserved.
//

import UIKit

class ListViewController: UITableViewController {

    var model: [[String: String]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListItemCell", forIndexPath: indexPath)
        cell.textLabel?.text = self.model[indexPath.row][ItemKey.Title] ?? ""
        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let cell = sender as? UITableViewCell,
            let indexPath = self.tableView.indexPathForCell(cell),
            let destination = segue.destinationViewController as? CardDetailsViewController {
            destination.cardItem = self.model[indexPath.row]
        }
    }
}
