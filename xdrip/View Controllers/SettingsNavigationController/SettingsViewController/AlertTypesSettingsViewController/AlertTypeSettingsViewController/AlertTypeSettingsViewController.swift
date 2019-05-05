import UIKit

/// a case per type of attribute that can be set in an AlerTypeSettingsView
fileprivate enum Setting:Int, CaseIterable {
    /// is it enabled or not
    case enabled = 0
    /// the name of the alert type
    case name = 1
    /// vibrate or not
    case vibrate = 2
    /// sound name
    case soundName = 3
    /// override mute or not
    case overridemute = 4
    /// snooze Via Notification on homescreen or not
    case snoozeViaNotification = 5
    /// default snoozeperiod when snoozing from homescreen
    case defaultSnoozePeriod = 6
}

/// edit or add an alert types,
final class AlertTypeSettingsViewController: UIViewController {
    
    // MARK: - Properties
    
    /// a tableView is used to display all alerttype properties - not the nicest solution maybe, but the quickest right now
    @IBOutlet weak var tableView: UITableView!
    
    // done button, to confirm changes
    @IBAction func doneButtonAction(_ sender: UIBarButtonItem) {
        doneButtonAction()
    }
    
    // to delete the alert type
    @IBAction func trashButtonAction(_ sender: UIBarButtonItem) {
        // delete the alerttype if one exists
        if let alertTypeAsNSObject = alertTypeAsNSObject {
            coreDataManager?.mainManagedObjectContext.delete(alertTypeAsNSObject)
            coreDataManager?.saveChanges()
        }
        
        // go back to alerttypes settings screen
        performSegue(withIdentifier: UnwindSegueIdentifiers.unwindToAlertTypesSettingsViewController.rawValue, sender: self)
    }

    @IBOutlet weak var trashButtonOutlet: UIBarButtonItem!
    
    /// the alerttype being edited - will only be used initially to initialize the temp properties used locally, and in the end to update the alerttype - if nil then it's about creating a new alertType
    private var alertTypeAsNSObject:AlertType?

    /// reference to coreDataManager
    private var coreDataManager:CoreDataManager?
    
    // MARK:- alerttype temp properties
    
    // following properties are used to temporary store alertType attributes which can be modified. The actual update of the alertType being processed will be done only when the user clicks the done button
    
    private var enabled = Constants.DefaultAlertTypeSettings.enabled
    private var name = Constants.DefaultAlertTypeSettings.name
    private var overrideMute = Constants.DefaultAlertTypeSettings.overrideMute
    private var snooze = Constants.DefaultAlertTypeSettings.snooze
    private var snoozePeriod = Constants.DefaultAlertTypeSettings.snoozePeriod
    private var vibrate = Constants.DefaultAlertTypeSettings.vibrate
    private var soundName = Constants.DefaultAlertTypeSettings.soundName
    
    // MARK:- public functions
    
    public func configure(alertType:AlertType?, coreDataManager:CoreDataManager) {
        self.alertTypeAsNSObject = alertType
        self.coreDataManager = coreDataManager
        
        // configure local temp alert type properties if alertType not nil - if alertType is nil then this viewcontroller is opened to create a ne alertType, in that case default values are used
        if let alertType = alertType {
            enabled = alertType.enabled
            name = alertType.name
            overrideMute = alertType.overridemute
            snooze = alertType.snooze
            snoozePeriod = alertType.snoozeperiod
            vibrate = alertType.vibrate
            soundName = alertType.soundname
        }
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Texts_AlertTypeSettingsView.editAlertTypeScreenTitle
        
        setupView()
    }
    
    // MARK: - View Methods
    
    private func setupView() {
        
        // if the alerttype still has alertEntries linked to it, or if it's about creating a new (yet unexisting) alerttype, then the trashbutton should be disabled
        if let alertEntries = alertTypeAsNSObject?.alertEntries, alertEntries.count > 0 {
            trashButtonOutlet.isEnabled = false
        }
        if alertTypeAsNSObject == nil {
            trashButtonOutlet.isEnabled = false
        }
        
        setupTableView()
    }
    
    // MARK: - private helper functions
    
    /// setup datasource, delegate, seperatorInset
    private func setupTableView() {
        if let tableView = tableView {
            tableView.separatorInset = UIEdgeInsets.zero
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    // helper function to transform the optional global variable coredatamanager in to a non-optional
    private func getCoreDataManager() -> CoreDataManager {
        if let coreDataManager = coreDataManager {
            return coreDataManager
        } else {
            fatalError("in AlertTypeSettingsViewController, coreDataManager is nil")
        }
    }
    
    /// to do when user cliks done button
    private func doneButtonAction() {
        // first check if name is a unique name
        let alertTypesAccessor = AlertTypesAccessor(coreDataManager: getCoreDataManager())
        for alertTypeAlreadyStored in alertTypesAccessor.getAllAlertTypes() {
            // if name == alertTypeAlreadyStored.name and alertTypeAlreadyStored is not the same object as alertTypeAsNSObject then not ok
            if alertTypeAlreadyStored.name == name && (alertTypeAsNSObject == nil || alertTypeAlreadyStored != alertTypeAsNSObject) {
                // define and present alertcontroller
                UIAlertController(title: Texts_Common.warning, message: Texts_AlertTypeSettingsView.alertTypeNameAlreadyExistsMessage).presentInOwnWindow(animated: true, completion: {})
                return
            }
        }
        
        // now either store the updated alertType or create a new one
        if let alertTypeAsNSObject = alertTypeAsNSObject {
            alertTypeAsNSObject.name = name
            alertTypeAsNSObject.enabled = enabled
            alertTypeAsNSObject.overridemute = overrideMute
            alertTypeAsNSObject.snooze = snooze
            alertTypeAsNSObject.snoozeperiod = snoozePeriod
            alertTypeAsNSObject.vibrate = vibrate
            alertTypeAsNSObject.soundname = soundName
        } else {
            alertTypeAsNSObject = AlertType(enabled: enabled, name: name, overrideMute: overrideMute, snooze: snooze, snoozePeriod: Int(snoozePeriod), vibrate: vibrate, soundName: soundName, alertEntries: nil, nsManagedObjectContext: getCoreDataManager().mainManagedObjectContext)
        }
        
        // save the alerttype
        coreDataManager?.saveChanges()
        
        // go back to alerttypes settings screen
        performSegue(withIdentifier: UnwindSegueIdentifiers.unwindToAlertTypesSettingsViewController.rawValue, sender: self)
    }
    
}

extension AlertTypeSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UITableViewDataSource and UITableViewDelegate protocol Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // if the alerttype is not enabled, then don't show all the other rows, just the first
        if !enabled {return 1}
        
        // if snooze via notifiation screen not enabled, then don't show
        //if !snooze {return Setting.allCases.count - 1}
        return Setting.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.reuseIdentifier, for: indexPath) as? SettingsTableViewCell else { fatalError("AlertTypeSettingsViewController cellforrowat, Unexpected Table View Cell ") }
        
        guard let setting = Setting(rawValue: indexPath.row) else { fatalError("AlertTypeSettingsViewController cellForRowAt, Unexpected setting") }
        
        // default value for accessoryView is nil
        cell.accessoryView = nil
        
        // configure the cell depending on setting
        switch setting {
            
        case .name:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeName
            cell.detailTextLabel?.text = name
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        case .enabled:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeEnabled
            cell.detailTextLabel?.text = nil
            cell.accessoryType = UITableViewCell.AccessoryType.none
            cell.accessoryView = UISwitch(isOn: enabled, action: {
                (isOn:Bool) in
                self.enabled = isOn
                tableView.reloadSections(IndexSet(integer: 0), with: .none)
            })
        case .vibrate:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeVibrate
            cell.detailTextLabel?.text = nil
            cell.accessoryType = UITableViewCell.AccessoryType.none
            cell.accessoryView = UISwitch(isOn: vibrate, action: {
                (isOn:Bool) in
                self.vibrate = isOn
                tableView.reloadRows(at: [IndexPath(row: Setting.vibrate.rawValue, section: 0)], with: .none) // just for case where status of switch is nog aligned with value
            })
        case .snoozeViaNotification:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeSnoozeViaNotification
            cell.detailTextLabel?.text = nil
            cell.accessoryType = UITableViewCell.AccessoryType.none
            cell.accessoryView = UISwitch(isOn: snooze, action: {
                (isOn:Bool) in
                self.snooze = isOn
                tableView.reloadRows(at: [IndexPath(row: Setting.snoozeViaNotification.rawValue, section: 0)], with: .none) // just for case where status of switch is nog aligned with value
            })
        case .defaultSnoozePeriod:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeDefaultSnoozePeriod
            cell.detailTextLabel?.text = snoozePeriod.description
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        case .soundName:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeSound
            cell.detailTextLabel?.text = soundName != nil ? soundName! == "" ? Texts_AlertTypeSettingsView.alertTypeNoSound : soundName! : Texts_AlertTypeSettingsView.alertTypeDefaultIOSSound
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        case .overridemute:
            cell.textLabel?.text = Texts_AlertTypeSettingsView.alertTypeOverrideMute
            cell.detailTextLabel?.text = nil
            cell.accessoryType = UITableViewCell.AccessoryType.none
            cell.accessoryView = UISwitch(isOn: overrideMute, action: {
                (isOn:Bool) in
                self.overrideMute = isOn
                tableView.reloadRows(at: [IndexPath(row: Setting.overridemute.rawValue, section: 0)], with: .none) // just for case where status of switch is nog aligned with value
            })
        }
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // only 1 section, namely the list of alert types
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let setting = Setting(rawValue: indexPath.row) else { fatalError("AlertTypeSettingsViewController didSelectRowAt, Unexpected setting") }
        
        // configure the cell depending on setting
        switch setting {
            
        case .name:
            let alert = UIAlertController(title: Texts_AlertTypeSettingsView.alertTypeName, message: Texts_AlertTypeSettingsView.alertTypeGiveAName, keyboardType: .alphabet, text: name, placeHolder: nil, actionTitle: nil, cancelTitle: nil, actionHandler: { (text:String) in
                self.name = text
                tableView.reloadRows(at: [IndexPath(row: Setting.name.rawValue, section: 0)], with: .none)
            }, cancelHandler: nil)
            // present the alert
            self.present(alert, animated: true, completion: nil)
        case .enabled:
            break // status is changed only when clicking the switch, not the row
        case .vibrate:
        break // status is changed only when clicking the switch, not the row
        case .snoozeViaNotification:
        break // status is changed only when clicking the switch, not the row
        case .defaultSnoozePeriod:
            let alert = UIAlertController(title: Texts_AlertTypeSettingsView.alertTypeDefaultSnoozePeriod, message: Texts_AlertTypeSettingsView.alertTypeGiveSnoozePeriod, keyboardType: .numberPad, text: snoozePeriod.description, placeHolder: nil, actionTitle: nil, cancelTitle: nil, actionHandler: { (text:String) in
                if let asdouble = text.toDouble() {
                    self.snoozePeriod = Int16(asdouble)
                    tableView.reloadRows(at: [IndexPath(row: Setting.defaultSnoozePeriod.rawValue, section: 0)], with: .none)
                }
            }, cancelHandler: nil)
            // present the alert
            self.present(alert, animated: true, completion: nil)

        case .soundName:
            // create array of all sounds, inclusive default ios sound and also empty string, which is "no sound"
            var sounds = Constants.Sounds.allSoundsByName()
            sounds.insert(Texts_AlertTypeSettingsView.alertTypeDefaultIOSSound, at: 0)
            sounds.insert(Texts_AlertTypeSettingsView.alertTypeNoSound, at: 0)
            
            // configure pickerViewData
            let pickerViewData = PickerViewData(withMainTitle: nil, withSubTitle: Texts_AlertTypeSettingsView.alertTypePickSoundName, withData: sounds, selectedRow: 0, withPriority: nil, actionButtonText: nil, cancelButtonText: nil, onActionClick: {(_ index: Int) in
                if index == 1 {
                    // default iOS sound was selected, set to nil
                    self.soundName = nil
                } else if index == 0 {
                    // no sound to play
                    self.soundName = ""
                } else {
                    self.soundName = sounds[index]
                }
                tableView.reloadRows(at: [IndexPath(row: Setting.soundName.rawValue, section: 0)], with: .none)
            }, onCancelClick: {})
            
            // create and present pickerviewcontroller
            PickerViewController.displayPickerViewController(pickerViewData: pickerViewData, parentController: self)

        case .overridemute:
            break // status is changed only when clicking the switch, not the row
        }
    }
}
    
/// defines perform segue identifiers used within AlertTypeSettingsViewController - there's only one at the moment, but there could be more in the future, that's why it's an enum
extension AlertTypeSettingsViewController {
    public enum SegueIdentifiers:String {
        
        /// to go from alerttypes settings screen to alert type settings screen
        case alertTypesToAlertTypeSettings = "alertTypesToAlertTypeSettings"
        
    }
    
    private enum UnwindSegueIdentifiers:String {
        
        /// to go back from alerttype settings screen to alerttypes settings screen
        case unwindToAlertTypesSettingsViewController = "unwindToAlertTypesSettingsViewController"
    }
}
