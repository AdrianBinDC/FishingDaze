//
//  JournalEditorViewController.swift
//  FishingDaze
//
//  Created by Vui Nguyen on 6/27/19.
//  Copyright © 2019 SunfishEmpire. All rights reserved.
//

import UIKit
import CoreData

class JournalEditorViewController: UITableViewController {
  @IBOutlet weak var waterLocationTextField: UITextField!
  @IBOutlet weak var moreLocationTextField: UITextField!
  
  @IBOutlet weak var datePicker: UIDatePicker!
  @IBOutlet weak var startTimePicker: UIDatePicker!
  @IBOutlet weak var endTimePicker: UIDatePicker!
  @IBOutlet weak var deleteEntryButton: UIButton!
  
  @IBOutlet weak var saveBarButton: UIBarButtonItem!
  
  @IBAction func deleteEntry(_ sender: Any) {
    print("we're going to delete an entry!")
    // Create the action buttons for the alert.
    let destroyAction = UIAlertAction(title: "Delete",
                                      style: .destructive) { (action) in
                                        // Respond to user selection of the action
    // find journal entry in Core Data and delete from Core Data
      self.findEntryByCreationDate(completion: { (journalEntryToDelete, error) in
        guard let entry = journalEntryToDelete else {
          print("couldn't find entry to delete!")
          return
        }

        do {
          self.managedContext.delete(entry)
          try self.managedContext.save()
          // unwind back to journal entry list
          self.performSegue(withIdentifier: "ReturnToJournalListSegue", sender: nil)
          //self.mapView.removeAnnotation(annotation)
        } catch let error as NSError {
          print("Could not save delete. \(error), \(error.userInfo)")
        }
    })

    }

    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .cancel) { (action) in
                                      // Respond to user selection of the action
    }

    let alert = UIAlertController(title: "Delete Journal Entry?",
                                  message: "",
                                  preferredStyle: .actionSheet)
    alert.addAction(destroyAction)
    alert.addAction(cancelAction)

    // On iPad, action sheets must be presented from a popover.
    alert.popoverPresentationController?.barButtonItem = saveBarButton

    self.present(alert, animated: true) {
      // The alert was presented
    }

  }


  @IBAction func cancelEditing(_ sender: Any) {
    //dismiss(animated: true, completion: nil)
    self.performSegue(withIdentifier: "ReturnToJournalListSegue", sender: nil)
  }
  
  @IBAction func saveEdits(_ sender: Any) {
    // save to Core Data

    // the completion handler should really be reloading the tableView
    //dismiss(animated: true, completion: saveJournalEntry)
    saveJournalEntry()
    self.performSegue(withIdentifier: "ReturnToJournalListSegue", sender: nil)
  }

  var appDelegate: AppDelegate!
  var managedContext: NSManagedObjectContext!
  var showDelete = false
  var creationDate: Date?
  var journalEntry: JournalEntry?
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem
    setUpCoreData()

    setDefaultTimes()
    showHideDelete()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setUpCoreData()
  }

  func setUpCoreData() {
    appDelegate = UIApplication.shared.delegate as? AppDelegate
    managedContext = appDelegate.persistentContainer.viewContext
  }

  func saveJournalEntry() {
    print("save changes!")

    // this is where we grab values from the pickers and save them somewhere
    let oldStartTime = startTimePicker.date
    let oldEndTime   = endTimePicker.date
    // if the user modified the day picker, make sure that's reflected in the startTime and endTime date
    let myCalendar = Calendar(identifier: .gregorian)

    let updatedStartTime = myCalendar.date(bySettingHour: myCalendar.component(.hour, from: oldStartTime),
                                         minute: myCalendar.component(.minute, from: oldStartTime),
                                         second: myCalendar.component(.second, from: oldStartTime), of: datePicker.date)

    let updatedEndTime = myCalendar.date(bySettingHour: myCalendar.component(.hour, from: oldEndTime),
                                         minute: myCalendar.component(.minute, from: oldEndTime),
                                         second: myCalendar.component(.second, from: oldEndTime), of: datePicker.date)

    // Save to Core Data if new entry
    if showDelete == false {
      let entity =
        NSEntityDescription.entity(forEntityName: "Entry",
                                   in: managedContext)!

      let entry = NSManagedObject(entity: entity,
                              insertInto: managedContext)

      let creationDate = Date()
      entry.setValue(updatedStartTime, forKeyPath: "startDate")
      entry.setValue(updatedEndTime, forKey: "endDate")
      entry.setValue(creationDate, forKey: "creationDate")
      do {
        try managedContext.save()
        print("Added entry, creationDate is: \(creationDate)")
        print("Added entry, startTime is: \(String(describing: updatedStartTime))")
        print("Added entry, endTime is: \(String(describing: updatedEndTime))\n")
      } catch let error as NSError {
        print("Could not save. \(error), \(error.userInfo)")
      }
    } else {
      // else search for entry by creationDate, edit entry in Core Data and then save!
      findEntryByCreationDate { (journalEntryEdited, error) in
        // grab data from all the controls and save here!!
        guard let entry = journalEntryEdited else {
          print("could not find entry here")
          return
        }

        entry.setValue(updatedStartTime, forKeyPath: "startDate")
        entry.setValue(updatedEndTime, forKey: "endDate")
        do {
          try self.managedContext.save()
          print("Edited entry, startTime is: \(String(describing: updatedStartTime))")
          print("Edited entry, endTime is: \(String(describing: updatedEndTime))\n")
        } catch let error as NSError {
          print("Could not save. \(error), \(error.userInfo)")
        }

      }
    }

  }

  func findEntryByCreationDate(completion: @escaping (Entry?, Error?) -> Void) {
    guard let journalEntry = journalEntry else {
      return
    }

    let creationDatePredicate = NSPredicate(format: "creationDate = %@", journalEntry.creationDate as NSDate)

    do {
      let fetchRequest:NSFetchRequest<Entry> = Entry.fetchRequest()
      let entries = try managedContext.fetch(fetchRequest)
      let entriesFound = (entries as NSArray).filtered(using: creationDatePredicate) as! [NSManagedObject]
      if entriesFound.count >= 1 {

        if let entryFound = entriesFound[0] as? Entry {
          DispatchQueue.main.async {
            completion(entryFound, nil)
          }
        }
      }
    } catch let error as NSError {

      print("Could not fetch or save from context. \(error), \(error.userInfo)")
      completion(nil, error)
    }

  }

  func setDefaultTimes() {
    if let journalEntry = journalEntry {
      datePicker.date = journalEntry.startDate
      startTimePicker.date = journalEntry.startDate
      endTimePicker.date = journalEntry.endDate
    } else {
      let origStartTime = startTimePicker.date
      // make the updated start time be 2 hours before the current time
      let timeInterval = TimeInterval(60*60*2)
      let updatedStartTime = origStartTime.addingTimeInterval(-timeInterval)
      startTimePicker.date = updatedStartTime
    }

    let myCalendar = Calendar(identifier: .gregorian)
    let ymd = myCalendar.dateComponents([.year, .month, .day], from: datePicker.date)
    print(ymd)
  }

  func showHideDelete() {
    deleteEntryButton.isHidden = showDelete == true ? false : true
    deleteEntryButton.isEnabled = showDelete == true ? true : false
  }
  // MARK: - Table view data source

  /*
   override func numberOfSections(in tableView: UITableView) -> Int {
   // #warning Incomplete implementation, return the number of sections
   return 0
   }

   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
   // #warning Incomplete implementation, return the number of rows
   return 0
   }
   */
  /*
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
   let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

   // Configure the cell...

   return cell
   }
   */

  /*
   // Override to support conditional editing of the table view.
   override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
   // Return false if you do not want the specified item to be editable.
   return true
   }
   */

  /*
   // Override to support editing the table view.
   override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
   if editingStyle == .delete {
   // Delete the row from the data source
   tableView.deleteRows(at: [indexPath], with: .fade)
   } else if editingStyle == .insert {
   // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
   }
   }
   */

  /*
   // Override to support rearranging the table view.
   override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

   }
   */

  /*
   // Override to support conditional rearranging of the table view.
   override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
   // Return false if you do not want the item to be re-orderable.
   return true
   }
   */

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */

}

extension JournalEditorViewController: UITextFieldDelegate {

}


