//
//  PeripheralServiceCharacteristicValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralServiceCharacteristicValuesViewController : UITableViewController {
   
    weak var characteristic         : Characteristic?
    let progressView                : ProgressView!
    var peripheralViewController    : PeripheralViewController?

    
    @IBOutlet var refreshButton :UIButton!
    
    struct MainStoryboard {
        static let peripheralServiceCharactertisticValueCell                = "PeripheralServiceCharacteristicValueCell"
        static let peripheralServiceCharacteristicEditDiscreteValuesSegue   = "PeripheralServiceCharacteristicEditDiscreteValues"
        static let peripheralServiceCharacteristicEditValueSeque            = "PeripheralServiceCharacteristicEditValue"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
        self.progressView = ProgressView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let characteristic = self.characteristic {
            self.navigationItem.title = characteristic.name
            if characteristic.isNotifying {
                self.refreshButton.enabled = false
            } else {
                self.refreshButton.enabled = true
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func viewDidAppear(animated:Bool)  {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"peripheralDisconnected", name:BlueCapNotification.peripheralDisconnected, object:self.characteristic?.service.peripheral)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
        self.updateValues()
    }
    
    override func viewDidDisappear(animated: Bool) {
        if let characteristic = self.characteristic {
            if characteristic.isNotifying {
                characteristic.stopUpdates()
            }
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destinationViewController as PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = self.characteristic
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditValueSeque {
            let viewController = segue.destinationViewController as PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = self.characteristic
            if let stringValues = self.characteristic?.stringValues {
                let selectedIndex = sender as NSIndexPath
                let names = stringValues.keys.array
                viewController.valueName = names[selectedIndex.row]
            }
        }
    }
    
    @IBAction func updateValues() {
        if let characteristic = self.characteristic {
            if characteristic.isNotifying {
                characteristic.startUpdates({
                        self.updateWhenActive()
                    }, afterUpdateFailed:{(error) in
                        self.presentViewController(UIAlertController.alertOnError(error) {(action) in
                    }, animated:true, completion:nil)
                })
            } else if characteristic.propertyEnabled(.Read) {
                self.progressView.show()
                characteristic.read({
                        self.updateWhenActive()
                        self.progressView.remove()
                    }, afterReadFailed:{(error) in
                        self.progressView.remove()
                        self.presentViewController(UIAlertController.alertOnError(error) {(action) in
                            self.navigationController?.popViewControllerAnimated(true)
                            return
                        }, animated:true, completion:nil)
                })
            }
        }
    }
    
    func peripheralDisconnected() {
        Logger.debug("PeripheralServiceCharacteristicValuesViewController#peripheralDisconnected")
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripehealConnected {
                self.progressView.remove()
                self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected") {(action) in
                        peripheralViewController.peripehealConnected = false
                    }, animated:true, completion:nil)
            }
        }
    }

    func didResignActive() {
        self.navigationController?.popToRootViewControllerAnimated(false)
       Logger.debug("PeripheralServiceCharacteristicValuesViewController#didResignActive")
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralServiceCharacteristicValuesViewController#didBecomeActive")
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let values = self.characteristic?.stringValues {
            return values.count
        } else {
            return 0;
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralServiceCharactertisticValueCell, forIndexPath:indexPath) as CharacteristicValueCell
        if let characteristic = self.characteristic {
            if let stringValues = characteristic.stringValues {
                let names = stringValues.keys.array
                let values = stringValues.values.array
                cell.valueNameLabel.text = names[indexPath.row]
                cell.valueLable.text = values[indexPath.row]
            }
            if characteristic.propertyEnabled(.Write) || characteristic.propertyEnabled(.WriteWithoutResponse) {
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        if let characteristic = self.characteristic {
            if characteristic.propertyEnabled(.Write) || characteristic.propertyEnabled(.WriteWithoutResponse) {
                if characteristic.discreteStringValues.isEmpty {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditValueSeque, sender:indexPath)
                } else {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue, sender:indexPath)
                }
            }
        }
    }
}
