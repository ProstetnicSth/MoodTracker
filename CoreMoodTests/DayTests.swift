//
//  DayTests.swift
//  MoodTracker
//
//  Created by Seyithan Teymur on 22/12/15.
//  Copyright © 2015 Brokoli. All rights reserved.
//

import XCTest
import CoreMood

class DayTests: XCTestCase {
    
    var sampleMoodStamp: MoodStamp {
        let good = arc4random_uniform(2) == 0
        let timeInterval = Double(-60 * Int(arc4random_uniform(10)))
        
        let timestamp = Date(timeIntervalSinceNow: timeInterval)
        return MoodStamp(mood: good ? .good : .bad, timestamp: timestamp)
    }
    
    func sampleMoodArrayWithCount(_ count: Int) -> [MoodStamp] {
        if count < 1 {
            return []
        }
        
        return (0..<count).map { _ in
            self.sampleMoodStamp
        }
    }

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testValues() {
        let stampArray = self.sampleMoodArrayWithCount(2)
        let day = Day(moodStamps: stampArray)
        
        XCTAssertEqual(day.moodStamps.count, stampArray.count)
    }
    
    func testDefaultValues() {
        let day = Day()
        XCTAssertNotNil(day.moodStamps, "Day's stamp array should not be nil")
        XCTAssertEqual(day.moodStamps.count, 0, "Day's stamp array should have an object count of 0")
    }
    
    func testEncoding() {
        let stampArray = self.sampleMoodArrayWithCount(2)
        let day = Day(moodStamps: stampArray)
        
        let dayData = NSKeyedArchiver.archivedData(withRootObject: day)
        XCTAssertGreaterThan(dayData.count, 0, "Encoded data should not be empty")
        
        let decodedDay = NSKeyedUnarchiver.unarchiveObject(with: dayData) as? Day
        XCTAssertNotNil(decodedDay, "Decoded day should not be nil")
        
        if let decodedDay = decodedDay {
            XCTAssertEqual(day, decodedDay, "Day and decoded day should be equal")
            XCTAssertEqual(decodedDay.moodStamps.count, stampArray.count, "Decoded day's stamp array should be equal to the original stamp array")
        }
    }
    
    func testMoodAddition() {
        let day = Day()
        
        for i in 0..<1 {
            let mood = i%2 == 0 ? Mood.good : Mood.bad
            day.addMood(mood)
            
            XCTAssertEqual(day.moodStamps.count, i+1, "Mood (\(i)) should be added")
            XCTAssertEqual(day.lastMoodStamp?.mood, mood, "Last moodstamp's mood should be equal to the last added mood")
        }
        
        XCTAssertEqual(day.moodStamps.count, 1, "Day should have 10 mood stamps")
    }
    
    func testMoodSorting() {
        let firstMoodStamp = MoodStamp(mood: .good, timestamp: Date(timeIntervalSinceNow: -10*60))
        let secondMoodStamp = MoodStamp(mood: .good)
        
        let day = Day(moodStamps: [secondMoodStamp, firstMoodStamp])
        XCTAssertEqual(day.lastMoodStamp, secondMoodStamp, "Day should have sorted moodstamps on init")
        
        let day2 = Day(moodStamps: [firstMoodStamp])
        day2.addMood(.bad)
        XCTAssertNotEqual(day2.lastMoodStamp, firstMoodStamp, "Day should sort moodstamps on addition")
    }
    
    func testMoodFrequencyCap() {
        let day = Day()
        
        let addFirst = day.addMood(.good)
        let addSecond = day.addMood(.good)
        
        XCTAssertTrue(addFirst, "Day should add the first mood")
        XCTAssertFalse(addSecond, "Day should not add the second mood")
        
        XCTAssertEqual(day.moodStamps.count, 1, "Day moodstamp count should be 1")
    }
    
    func testDefaultMoodAdditionInterval() {
        let day = Day()
        
        let now = Date()
        day.addMood(.good)
        let timeIntervalUntilNextAddition = day.timeIntervalUntilNextMoodAddition
        
        XCTAssertEqualWithAccuracy(now.timeIntervalSinceNow, day.lastMoodStamp!.timestamp.timeIntervalSinceNow, accuracy: 1, "Day's last added mood time stamp should be now")
        XCTAssertEqualWithAccuracy(5*60, timeIntervalUntilNextAddition, accuracy: 2, "Time interval until next mood addition should be close to 5 mins")
        
        XCTAssertFalse(day.addMood(.good))
    }
    
    func testPastMoodAdditionInterval() {
        let pastMood = MoodStamp(mood: .good, timestamp: Date(timeIntervalSinceNow: -4*60))
        let day = Day(moodStamps: [pastMood])
        let timeIntervalUntilNextAddition = day.timeIntervalUntilNextMoodAddition
        
        XCTAssertEqualWithAccuracy(1*60, timeIntervalUntilNextAddition, accuracy: 2, "Time interval until next mood addition should be close to 1 min")
        
        XCTAssertFalse(day.addMood(.good))
    }
    
    func testEquality() {
        let control = DayDate(day: 9, month: 12, year: 1989)
        
        let date1 = DayDate(day: 9, month: 12, year: 1989)
        let date2 = DayDate(day: 29, month: 6, year: 1990)
        let date3 = DayDate(day: 10, month: 12, year: 1989)
        let date4 = DayDate(day: 9, month: 11, year: 19889)
        let date5 = DayDate(day: 9, month: 12, year: 2015)
        
        XCTAssertEqual(control, date1)
        XCTAssertNotEqual(control, date2)
        XCTAssertNotEqual(control, date3)
        XCTAssertNotEqual(control, date4)
        XCTAssertNotEqual(control, date5)
    }
    
    func testDateAndDateComponentsEquality() {
        let today = Date()
        let todayComponents = Calendar.current().components([.day, .month, .year], from: today)
        
        let date1 = DayDate(date: today)
        let date2 = DayDate(dateComponents: todayComponents)
        
        XCTAssertEqual(date1, date2, "Dates from NSDate and NSDateComponents should be equal")
        
        let dateBack1 = date1.date
        let dateBack2 = date2.date
        
        XCTAssertNotNil(dateBack1 ?? dateBack2, "Dates from DayDates should not be nil")
        if let dateBack1 = dateBack1, let dateBack2 = dateBack2 {
            XCTAssertTrue(Calendar.current().isDate(dateBack1, inSameDayAs: dateBack2), "Dates should be in the same day")
        }
    }
    
    func testYesterday() {
        let today = Date()
        let yesterday = Calendar.current().date(byAdding: .day, value: -1, to: today, options: [])!
        XCTAssertTrue(Calendar.current().isDateInYesterday(yesterday), "Wut?")
        
        let todayDay = DayDate()
        let yesterdayDay = todayDay.dateWithDaysAfter(-1)
        XCTAssertNotNil(yesterdayDay, "Yesterday should not be nil")
        
        if let yesterdayDay = yesterdayDay {
            XCTAssertTrue(Calendar.current().isDateInYesterday(yesterdayDay.date!))
        }
    }
    
    func testComparison() {
        let earlierDate = Calendar.current().date(byAdding: .month, value: -1, to: Date(), options: [])!
        let laterDate = Calendar.current().date(byAdding: .month, value: 1, to: Date(), options: [])!
        
        let control = DayDate()
        let earlier = DayDate(date: earlierDate)
        let later = DayDate(date: laterDate)
        
        XCTAssertTrue(earlier < control)
        XCTAssertTrue(later > control)
        XCTAssertTrue(earlier < later)
    }

}
