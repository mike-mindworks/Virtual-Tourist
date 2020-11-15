//
//  Location+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Mike Allan on 2020-11-02.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var page: Int32
    @NSManaged public var photos: NSOrderedSet?

}

// MARK: Generated accessors for photos
extension Location {

    @objc(insertObject:inPhotosAtIndex:)
    @NSManaged public func insertIntoPhotos(_ value: LocationPhoto, at idx: Int)

    @objc(removeObjectFromPhotosAtIndex:)
    @NSManaged public func removeFromPhotos(at idx: Int)

    @objc(replacePhotosAtIndexes:withPhotos:)
    @NSManaged public func replacePhotos(at indexes: NSIndexSet, with values: [LocationPhoto])

    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: LocationPhoto)
    /*

    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: LocationPhoto)

    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: LocationPhoto)

    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)

    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)
 */

}
