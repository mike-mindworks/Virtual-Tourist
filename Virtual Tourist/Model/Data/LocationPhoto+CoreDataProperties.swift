//
//  LocationPhoto+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Mike Allan on 2020-11-02.
//
//

import Foundation
import CoreData


extension LocationPhoto {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationPhoto> {
        return NSFetchRequest<LocationPhoto>(entityName: "LocationPhoto")
    }

    @NSManaged public var photoId: String?
    @NSManaged public var photoSecret: String?
    @NSManaged public var serverId: String?
    @NSManaged public var location: Location?

}
