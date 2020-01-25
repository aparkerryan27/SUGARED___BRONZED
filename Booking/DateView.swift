//
//  DateViewController.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/12/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import JTAppleCalendar
import NVActivityIndicatorView
import Firebase


class DateView: UIViewController {
    
    
    var activityIndicator: NVActivityIndicatorView!
    var activityIndicatorContainerView: UIView!
    var isLoading: Bool? {
        didSet {
            DispatchQueue.main.async {
                self.timesTableView.isHidden = self.isLoading! //if loading, hidden
                self.activityIndicator.isHidden = !self.isLoading! //if loading, not hidden
                self.activityIndicatorContainerView.isHidden = !self.isLoading! //if loading, not hidden
            }
        }
    }
    
    var currentCell: (DateCell, Date, CellState)?
    
    var monthCalendarHeight: CGFloat = 0
    let daysLabelHeight: CGFloat = 30
    
    var currentView = "month"
    
    var dateFormatter = DateFormatter() {
        didSet {
            dateFormatter.timeZone = Calendar.current.timeZone
        }
    }
    let calendarFormatter = NSCalendar.current
    var today = Date()
    var oneMonthFromToday: Date?
    var twoMonthsFromToday: Date?
    
    var loadAppointments = true
    var firstViewLoad = true
    
    var alert: UIAlertController?
    
    
    @IBOutlet weak var containerShadowView: UIView! {
        didSet {
            // setup shadowing rules, and do the unique shadowing when the view changes
            containerShadowView.layer.masksToBounds = false
            containerShadowView.layer.shadowColor = UIColor.black.cgColor
            //offsetting the height makes the shadow harsher
            containerShadowView.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
            containerShadowView.layer.shadowOpacity = 0.3
        }
    }
    
    @IBOutlet weak var calendar: JTAppleCalendarView! {
        didSet {
            calendar.backgroundColor = UIColor.white
            calendar.minimumLineSpacing = 0
            calendar.minimumInteritemSpacing = 0
        }
    }
    

    @IBOutlet weak var heightConstraint: NSLayoutConstraint!

    @IBOutlet weak var weekView: UIView!
    
    @IBOutlet weak var mondayView: UILabel!
    @IBOutlet weak var tuesdayView: UILabel!
    @IBOutlet weak var wednesdayView: UILabel!
    @IBOutlet weak var thursdayView: UILabel!
    @IBOutlet weak var fridayView: UILabel!
    @IBOutlet weak var saturdayView: UILabel!
    @IBOutlet weak var sundayView: UILabel!
    
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var chosenDateLabel: UILabel!
    
    
    @IBOutlet weak var timesTableView: UITableView!

    @objc func switchMonthOrWeekView() {
    
        //set the adjusted calendar height for the month view on the first load
        if monthCalendarHeight == 0 { monthCalendarHeight = heightConstraint.constant - daysLabelHeight }
        
        if currentView == "week" {
            heightConstraint.constant = daysLabelHeight + monthCalendarHeight
            currentView = "month"
        } else if currentView == "month" {
            currentView = "week"
            heightConstraint.constant = daysLabelHeight + (monthCalendarHeight / 5)
        }
        
        self.view.layoutIfNeeded()
        
        self.calendar.reloadData(withanchor: nil, completionHandler: {
            if let previousCell = self.currentCell {
                self.calendar.scrollToDate(previousCell.1, triggerScrollToDateDelegate: false, animateScroll: false) {
                    self.loadAppointments = false
                    self.calendar.selectDates([previousCell.1], triggerSelectionDelegate: true)
                }
            }
        } )

    }
    
   
    @objc func back() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstViewLoad = true
        
        //MARK: - Add Back Button to Nav
        let backButton: UIButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "back_arrow"), for: .normal)
        backButton.addTarget(self, action: #selector(back), for: UIControl.Event.touchUpInside)
        let backBarButton = UIBarButtonItem(customView: backButton)
        backButton.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
        self.navigationItem.leftBarButtonItems = [backBarButton]
        
        //MARK: - Setup ActivityIndicator
        activityIndicatorContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        activityIndicatorContainerView.center = view.center
        activityIndicatorContainerView.backgroundColor = Design.Colors.blue.withAlphaComponent(0.7)
        activityIndicatorContainerView.layer.cornerRadius = 4
        activityIndicatorContainerView.layer.masksToBounds = true
        self.view.addSubview(activityIndicatorContainerView)
        
        activityIndicator = NVActivityIndicatorView(frame: CGRect(x: view.center.x - 30, y: view.center.y-20, width: 60, height: 45), type: .ballPulseSync , color: .white, padding: 5)
        activityIndicator.center = view.center
        self.view.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        activityIndicatorContainerView.isHidden = false
        
        //MARK: - Add SwitchMonthOrWeekView Button
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UIImage(named: "calendar_icon"), for: .normal)
        button.addTarget(self, action: #selector(switchMonthOrWeekView), for: UIControl.Event.touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        button.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
        button.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
        self.navigationItem.rightBarButtonItems = [barButton]
        
        //MARK: - Create Important Dates
        today = calendarFormatter.startOfDay(for: Date())
        oneMonthFromToday = today.addingTimeInterval(1 * 2592000)
        twoMonthsFromToday = today.addingTimeInterval(2 * 2592000)
        
        //MARK: - Delegates/DataSources Configuration
        calendar.calendarDelegate = self
        calendar.calendarDataSource = self
        timesTableView.delegate = self
        timesTableView.dataSource = self
        
        //MARK: - Format and Search FirstDateAvailable
        AppointmentSearch.availableAppointments = []
        
        self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        AppointmentSearch.startTime = self.dateFormatter.string(from: self.today)
        AppointmentSearch.endTime = self.dateFormatter.string(from: self.oneMonthFromToday!)
        
        self.isLoading = true
        BookerAPI().checkFirstDateAvailableForAppointment(methodCompletion: { (success, error) -> Void in

            guard success else {
                print("Failure to Get First Date Available Appointment Times: \(error)")
                DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false }
                return
            }
        
            if self.calendar.selectedDates == [] {
                DispatchQueue.main.async {
                    self.calendar.scrollToDate(AppointmentSearch.firstDateAvailable!, triggerScrollToDateDelegate: false) {
                        self.isLoading = false
                        self.calendar.selectDates([AppointmentSearch.firstDateAvailable!], triggerSelectionDelegate: true)
                        
                    }
                }
            } else {
                print("date already selected")
            }            
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("DateView", screenClass: "app")
        
        //MAR: - Prevent Accidental Reloading on each View Appear
        guard !firstViewLoad else {
            firstViewLoad = false
            return
        }
        self.calendar.reloadData(withanchor: nil, completionHandler: {
            if let previousCell = self.currentCell {
                self.calendar.scrollToDate(previousCell.1, triggerScrollToDateDelegate: false, animateScroll: false) {
                    self.calendar.selectDates([previousCell.1], triggerSelectionDelegate: true)
                }
            }
        } )
    }
    
}

extension DateView: JTAppleCalendarViewDataSource {
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        if currentView == "month" {
            return ConfigurationParameters(startDate: today, endDate: twoMonthsFromToday!, numberOfRows: 5, generateInDates: .forAllMonths, generateOutDates: .tillEndOfRow, firstDayOfWeek: .monday, hasStrictBoundaries: true)
            
        } else { //currentView == "week"
            return ConfigurationParameters(startDate: today, endDate: twoMonthsFromToday!, numberOfRows: 1, generateInDates: .off, generateOutDates: .off, firstDayOfWeek: .monday, hasStrictBoundaries: false)
            
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCell
        configureCell(cell: cell, cellState: cellState, date: date)
        return cell
    }
    
    func configureCell(cell: DateCell, cellState: CellState, date: Date) {
        
        cell.dateLabel.text = cellState.text
        cell.selectedView.isHidden = true
        cell.dateLabel.textColor = .black
        
        //MARK: - Out of Bounds Coloration
        if currentView == "month" && cellState.dateBelongsTo != .thisMonth{
            cell.dateLabel.textColor = UIColor.lightGray
        }
        
//TODO: - See if this differentiation should apply on Today or FirstAvailableDay, UI Test
        if date == today {
            cell.dateLabel.textColor = Design.Colors.blue
        }
    }
    
}


extension DateView: JTAppleCalendarViewDelegate {
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        
        //MARK: - Prevent Selection in Edge Cases
        guard cellState.dateBelongsTo != .previousMonthOutsideBoundary && cellState.dateBelongsTo != .followingMonthOutsideBoundary else {
            print("date outside boundary")
            return
        }
        guard !isLoading! else {
            print("can't select date, currently loading")
            return
        }
        
        //MARK: - Scroll View for New Month
        guard cellState.dateBelongsTo == .thisMonth || currentView == "week" else {
            print("switching view to selected date outside boundary")
            calendar.scrollToDate(date, triggerScrollToDateDelegate: false) {
                calendar.selectDates([date], triggerSelectionDelegate: true)
            }
            return
        }
        
        //MARK: - Set Day of Week
        guard let dateCell = cell as? DateCell else {
            print("issue with the dateCell formatting")
            return
        }
        if let previousCell = currentCell {
            mondayView.textColor = Design.Colors.gray
            tuesdayView.textColor = Design.Colors.gray
            wednesdayView.textColor = Design.Colors.gray
            thursdayView.textColor = Design.Colors.gray
            fridayView.textColor = Design.Colors.gray
            saturdayView.textColor = Design.Colors.gray
            sundayView.textColor = Design.Colors.gray
            
            _ = configureCell(cell: previousCell.0, cellState: previousCell.2, date: previousCell.1)
        }
        let weekDay = calendarFormatter.component(.weekday, from: date)
        if weekDay == 2 {
            mondayView.textColor = Design.Colors.blue
        } else if weekDay == 3 {
            tuesdayView.textColor = Design.Colors.blue
        } else if weekDay == 4 {
            wednesdayView.textColor = Design.Colors.blue
        } else if weekDay == 5 {
            thursdayView.textColor = Design.Colors.blue
        } else if weekDay == 6 {
            fridayView.textColor = Design.Colors.blue
        } else if weekDay == 7 {
            saturdayView.textColor = Design.Colors.blue
        } else if weekDay == 1 {
            sundayView.textColor = Design.Colors.blue
        }
        
        dateCell.selectedView.isHidden = false
        dateCell.dateLabel.textColor = UIColor.white
        currentCell = (dateCell, date, cellState)
        
        //MARK: - First Date Available Configuration
        guard AppointmentSearch.firstDateAvailable != nil else {
            print("AppointmentSearch.firstDateAvailable isn't known yet")
            infoLabel.isHidden = true
            return
        }
        
        if Calendar.current.isDate(date, inSameDayAs: AppointmentSearch.firstDateAvailable!) {
            infoLabel.isHidden = false
        } else {
            infoLabel.isHidden = true
        }
        
        //MARK: - Prevent Double Selection on SwitchMonthToWeekView
        guard loadAppointments else {
            print("not loading appointments because of loadAppointments being false")
            loadAppointments = true
            if AppointmentSearch.availableAppointments.count == 0 {
                self.alert = UIAlertController(title: "bummer!", message: "no available appointments on this day, our apologies!", preferredStyle: .alert)
                self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(self.alert!, animated: true, completion: nil)
                return
            }
            return
        }
        
        //MARK: - Date Label
        dateFormatter.dateFormat = "EEEE, MMMM d"
        let dateString = dateFormatter.string(from: date).uppercased()
        chosenDateLabel.text = dateString
        
        
        //MARK: - Format Start Time and Perform API Request
        self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let startTime = "\(self.dateFormatter.string(from: date))-08:00"

        AppointmentSearch.startTime = startTime
        self.isLoading = true
        
        BookerAPI().checkAvailableAppointments(methodCompletion: { (success, error) -> Void in
            guard success else {
                print("Failure to Get Available Appointment Times: \(error)")
                DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false }
                self.isLoading = false
                return
            }
            
            self.isLoading = false
            
            DispatchQueue.main.async {
                self.timesTableView.reloadData()
                
                if AppointmentSearch.availableAppointments.count == 0 {
                    
                    self.alert = UIAlertController(title: "bummer!", message: "no available appointments on this day, our apologies!", preferredStyle: .alert)
                    self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(self.alert!, animated: true, completion: nil)
                    return
                }
            }
        })
    }
    
    func calendarDidScroll(_ calendar: JTAppleCalendarView) {  /* unused */ }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        for date in visibleDates.monthDates {
            if date.date == currentCell?.1 {
                if let cell = currentCell {
                    self.calendar.selectDates([cell.1], triggerSelectionDelegate: true)
                }
            }
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, shouldSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) -> Bool {
        return date >= today
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        // This function should have the same code as the cellForItemAt function
        let cell = cell as! DateCell
        configureCell(cell: cell, cellState: cellState, date: date)
    }

}

extension DateView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCell") as! TimeCell
        cell.selectionStyle = .none
        
        guard AppointmentSearch.availableAppointments.count != 0 else {
            return cell
        }
        
        guard indexPath.row < AppointmentSearch.availableAppointments.count else {
            print("index error for available appointments")
            cell.frame = .zero
            return cell
        }
        
        let appointment: Appointment = AppointmentSearch.availableAppointments[indexPath.row]
        
        cell.timeLabel.text = "\(appointment.startTimeHuman) - \(appointment.endTimeHuman)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension DateView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AppointmentSearch.appointmentSelected = AppointmentSearch.availableAppointments[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "toConfirmationSegue", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppointmentSearch.availableAppointments.count
    }
}

class DateCell: JTAppleCell {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var selectedView: UIView! {
        didSet {
            selectedView.layer.cornerRadius = (self.frame.width - 10) / 2
            selectedView.layer.masksToBounds = true
        }
    }
}

class TimeCell: UITableViewCell {
    @IBOutlet weak var timeLabel: UILabel!
}
