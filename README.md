## Starting up

To start, check out https://github.com/gdgriga/firebase-ios.
The project is almost complete implementation of a very basic task manager. All data is hardcoded, no Firebase setup done whatsoever.

The goal is to implement all Firebase integration during the workshop on your own. To assist you and to catch up if you're behind, there are checkpoint branches which would allow you to switch to a complete implementation of each particular step. 

`master` is pointing the same place as `setup` branch, and is ready to start the integration.
Do a

    pod install

and run the app. Press Sign In and you should see fake data.

## Firebase Setup

Class presentation will tell you all about creating the Firebase project itself, and itegration will be guided by Firebase Console. The gist of it is downloading `GoogleService-Info.plist` and adding it to the project, as well as adding `Firebase` dependency to `Podfile`:

    pod 'Firebase'

and initialising it in `AppDelegate.swift`:

    FIRApp.configure()

Detailed integration guide can be found in Firebase docs: https://firebase.google.com/docs/ios/setup

Run the app and verify Firebase didn't crash or anything. It won't chance any app behaviour just yet.

## Authentication

### Email sign in and sign up

If you want to skip right to this step, switch to `auth` branch. It is prepared for authenication business. Be ware that `GoogleService-Info.plist` still has to be downloaded to a proper place, because it's different for each project.

Docs for this step are found here: https://firebase.google.com/docs/auth/ios/password-auth

First, you have to add a new dependency for auth module:

    pod 'FirebaseAuth'

Now using `import FirebaseAuth` you have access to the `FIRAuth.auth()` object, which handles authentication for you. After enabling email method in the Firebase project you have to modify `SignInViewController`'s `signInTapped()` and `signUpTapped()` to use proper authentication methods, and call their current method bodies only in case of success.

Methods you are looking for are [`createUserWithEmail(email, password:, completion:)`](https://firebase.google.com/docs/reference/ios/firebaseauth/interface_f_i_r_auth.html#aeaee7fcef878990954f8e72f7278cd7d) and [`signInWithEmail(email, password:, completion:)`](https://firebase.google.com/docs/reference/ios/firebaseauth/interface_f_i_r_auth.html#a4156646de978ff01c961edb6eab8f937). 

To keep the other parts of the app working, please also save user ID to in `signInSuccessful()`:
   
    AppState.sharedInstance.ownUserID = FIRAuth.auth()?.currentUser?.uid

and add [`signOut()`](https://firebase.google.com/docs/reference/ios/firebaseauth/interface_f_i_r_auth.html#ab0d5111f05c3f1906243852cc8ef41b1) call to `signOutTapped()` in `BoardViewController`.

### Google Sign In

This is an optional step, but Google sign in becomes handy when testing. Implementing it is best described in the guide: https://firebase.google.com/docs/auth/ios/google-signin

Some comments on the guide's steps:
* `FirebaseWorkshop-Bridging-Header.h` is already created, just add a new import in there.
* URL scheme has to be your unique project's scheme. Taking it from this repo's commit won't work with your IDs.
* I suggest implementing both `GIDSignInDelegate, GIDSignInUIDelegate` in `SignInViewController` instead of `AppDelegate`. You can get it from `didFinishLaunchingWithOptions` by doing performing `self.window?.rootViewController as? SignInViewController`.
* The UIView for the button is already there. Once you have the right dependency integrated, just change its class in the Storyboard.

Upon successful auth, call same methods when you sign in with Google as when you created an account, namely

    self.createUserInCustomDatabase()
    self.signInSuccessful()

## Database integration

If you want to skip right to this step, check out `database` branch. 

The journey starts by adding another dependency:

    pod 'Firebase/Database'

and using `import FirebaseDatabase` in the relevant files. The start of the database guide by Google can be found here: https://firebase.google.com/docs/database/ios/start

In this step you'll have to do the most amounts of coding. You'll have to create and fetch users, then do the same for tasks as well as implement update and delete. 

### Users

To start off, we need to create a new entry in the `users` tree of the database when we sign up. That's why you had to call `createUserInCustomDatabase()` when creating a user. Modify the method in `SignInViewController` and add creation of the user. To create a user, all you have to do is call [`setValue()`](https://firebase.google.com/docs/database/ios/save-data) on a database reference, but the trickiest part is usually getting to that reference.

In our case, we don't want to have child nodes of users tree to use autoIDs, like Google's guide suggests. We want to use IDs of what Firebase returns as `uid` of the user. Getting to the database reference of a just created user would be

    if let currentUser = FIRAuth.auth()?.currentUser {
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child("users").child(currentUser.uid)
    }

You should call `setValue` on the returned object with a newly created dictionary object, but it will override the user every time you sign in with Google. If you want to use it, you'll have to also read data from that child node by using a method similar to `observeSingleEventOfType` and check if the data already exists:

    databaseRef.child("users").child(currentUser.uid).observeSingleEventOfType(.Value, withBlock: { snapshot in
        if !snapshot.exists() {
            var userEntry: [String: AnyObject] = [:]
            userEntry[UserKey.Email] = currentUser.email
            userEntry[UserKey.Avatar] = currentUser.photoURL?.absoluteString
            userEntry[UserKey.Karma] = 0
            snapshot.ref.setValue(userEntry)
        }
    })

This excersice gives you an overview of the reading data and creating data already. Let's move on to getting more users.

To allow easy selection of the possible task assignees, as well as control of the own avatar we suggest keeping a global list of users at hand. One of the ways to do it, is add to the `AppState` something like this:

    var allUsers: [String: [String: AnyObject]] = [:]
    
and load it from `BoardViewController`. But unlike the last time, when you checked for user data only once, we're gonna use the power of the realtime database and keep all our users in sync with the server data. To do that, you're gonna have to use [`observeEventType()`](https://firebase.google.com/docs/reference/ios/firebasedatabase/interface_f_i_r_database_reference.html#a92d618b443c649ba9f8c9d938a478c99) methods.

Firebase allows listening for subtree changes or for the value of the whole tree, whichever it more convenient. Let's start by listening to all changes in users and subscibe to [`.Value` event types](https://firebase.google.com/docs/database/ios/retrieve-data#value_events). Implement a method which loads users:

    FIRDatabase.database().reference().child("users").observeEventType(.Value) { (snapshot: FIRDataSnapshot) -> Void in
        if let users = snapshot.value as? UsersDictionary {
            AppState.sharedInstance.allUsers = users
        }
    }

and see if you're getting anything. When you are, start using `AppState.sharedInstance.allUsers` instead of all places in the project that used to use `MockUserModel`. 
Then move the `self.displayAvatar()` method so that it is only called when you have the actual data, not in `viewDidLoad()`.

### Task List

Getting `.Value` updates is slow and boring. For tasks, let's do the proper way and use [`.Child*` events](https://firebase.google.com/docs/database/ios/retrieve-data#child_events). Added tasks are easy. For example, given that you store database reference and tasks list in the properties in `BoardViewController`:

    self.databaseRef?.child("tasks").observeEventType(.ChildAdded) { (snapshot: FIRDataSnapshot) -> Void in
        self.tasks.append(snapshot)
        //self.updateChildControllers()
    }

Now, to remove and change the existing tasks, you'll have to listen to two more events and find relevant objects in task list and update or remove them. Updated snapshots won't be the same object, so you'll need to implement `indexOf()` comparing `snapshot.key` fields: they're the IDs you're looking for.

To propagate the changes down into the actual list controllers, you'll have to change them to accept `FIRDataSnapshot`s instead of plain dictionaries and pass a fitered subset of data. Here's a way to update them if you don't want to filter them youself. Once you have read data in them, remove references to hardcoded cards from `MockListModel`.

    private func updateChildControllers() {
        for (index, key) in Collection.all.enumerate() {
            let lvc = self.listViewControllers[index]
            lvc.model = self.tasks.filter() { item in
                let value = item.value as? [String: String]
                return value != nil && value![ItemKey.Collection] == key
            }
            lvc.tableView.reloadData()
        }
    }
    
### Task Details

To implement task editing, you'll have to go into `CardDetailsViewController` and start storing `FIRDataSnapshot` there as well if you don't wanna redownload the tasks in details screen. Load the value from the snapshot into the card, and save upon leaving the screen by accessing `snapshot.ref.setValue()`, just like you did with `users`.

When a user changes the list of the task at hand, his karma increases or decreases. So, when you implement all changes in the card, don't forget to update `users` database for your current user and save result from `self.userKarmaPoints()` into your karma value, and don't be a cheat!

## Storage

If you want to skip to this step... wait, why would you? The last one was most fun! Anyway, just in case there's a branch called `storage` which has all database logic ready.

We are using storage to save image attachments to the tasks. Add a `Firebase/Storage` pod dependecy to the project and `import FirebaseStorage` where needed.

Loading attachments is quite easy, use the [`FIRStorage.storage().referenceForURL().dataWithMaxSize()`](https://firebase.google.com/docs/storage/ios/download-files) method and just collect data from the callback. Data can be used to fill a `UIImageView` right away, do so for `self.attachmentImageView.image` in `CardDetailsViewController`.

Deleting is even easier with `deleteWithCompletion()`, but uploading is a little tricker. First, you have to prepare storage and use _your storage ID_:

    let storageRef = FIRStorage.storage().referenceForURL("gs://YOURID.appspot.com")

Then you have to prepare what you're uploading. The easiest way, once you get the `UIImage` from the image picker, is to just dump the data like this: 

    let imageData = UIImageJPEGRepresentation(image, 0.8)
    let imagePath = "attachments/" + NSUUID().UUIDString + ".jpg"
    let metadata = FIRStorageMetadata()
    metadata.contentType = "image/jpeg"

and then use a `storageRef.child(imagePath).putData()` method. We use NSUUID to avoid same filenames in the storage. Once you upload the file, you'll receive updated `metadata` object. Call `path` and save it to your task's `attachment` field.

In `CardDetailsViewController` image picking is implemented, but you'll have to manipulate `self.attachmentImageView` and `self.removeAttachmentButton` depending on what is in your task's attachment, and don't forget to clean up attachment when you delete a task as well.

## Next Steps

We'd like you to try remote configuration, analytics, and to catch a crash, but you're without a proper guide there. So, if you weren't able to complete everything in time or just want to peek how everything else was done as an example, you can check out `remote-config` branch.
