//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Mike Allan on 2020-10-12.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var fetchResultsController: NSFetchedResultsController<Location>!
    
    var annotations: [MKAnnotation]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the back button title for the Photo Album View
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "OK", style: .plain, target: nil, action: nil)

        setupFetchedResultsController()
        
        mapView.delegate = self
        
        // Look to see if the map location and zoom level was saved during the last run
        let defaults = UserDefaults.standard
        let latitude = defaults.double(forKey: "latitude")
        let longitude = defaults.double(forKey: "longitude")
        let latitudeDelta = defaults.double(forKey: "latitudeDelta")
        let longitudeDelta = defaults.double(forKey: "longitudeDelta")
        if latitude != 0.0 && longitude != 0.0 && latitudeDelta != 0.0 && longitudeDelta != 0.0 {
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)
        }
        
        // Generate long-press UIGestureRecognizer.
        let myLongPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        myLongPress.addTarget(self, action: #selector(recognizeLongPress(_:)))
        
        // Added UIGestureRecognizer to MapView.
        mapView.addGestureRecognizer(myLongPress)
        
        // Register for notification when the app closes
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "locations")
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            // Convert each Location result to an annotation
            for locationResult in result {
                let latitude = locationResult.latitude
                let longitude = locationResult.longitude
                let locationCoordinate = CLLocationCoordinate2D.init(latitude: latitude, longitude: longitude)
                
                // Generate a pin.
                let locationPin: MKPointAnnotation = MKPointAnnotation()
                
                // Set the coordinates.
                locationPin.coordinate = locationCoordinate
                
                // Set the title.
                locationPin.title = "Open Photo Album"
                
                // Add the annotation to the map
                mapView.addAnnotation(locationPin)
            }
        }
    }
    
    @objc private func appMovedToBackground() {
        
        let defaults = UserDefaults.standard
        // Save location
        let latitude = mapView.region.center.latitude
        let longitude = mapView.region.center.longitude
        // Save zoom level
        let latitudeDelta = mapView.region.span.latitudeDelta
        let longitudeDelta = mapView.region.span.longitudeDelta
        // Persist it all to UserDefaults
        defaults.setValue(latitude, forKey: "latitude")
        defaults.setValue(longitude, forKey: "longitude")
        defaults.setValue(latitudeDelta, forKey: "latitudeDelta")
        defaults.setValue(longitudeDelta, forKey: "longitudeDelta")

    }
    
    // A method called when long press is detected.
    // Creates the pin and when you call mapView.addAnnotation it calls
    // the mapView delegate method below this method to generate the pinView
    @objc private func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        // Do not generate pins many times during long press.
        if sender.state != UIGestureRecognizer.State.began {
            return
        }
        
        // Get the coordinates of the point you pressed long.
        let location = sender.location(in: mapView)
        
        // Convert location to CLLocationCoordinate2D.
        let locationCoordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        
        // Generate a pin.
        let locationPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set the coordinates.
        locationPin.coordinate = locationCoordinate
        
        // Set the title.
        locationPin.title = "Open Photo Album"
        
        // Add the annotation to the map.
        mapView.addAnnotation(locationPin)
        
        // Add the location to the dataController
        addLocation(locationCoordinate)
    }
    
    // TODO: Need to be maintaining this somewhere, the managed object is what
    // links to the database
    //
    // Why is this challenging?
    // -> Location created here is a Managed Object
    // -> locationCoordinate being passed in is a CLLocationCoordinate2D
    // -> The locationCoordinate is part of the locationPin MKPointAnnotation
    // -> I need to be able to add the Location Managed Object to the MKPointAnnotation
    func addLocation(_ locationCoordinate: CLLocationCoordinate2D) {
        let location = Location(context: dataController.viewContext)
        location.latitude = locationCoordinate.latitude
        location.longitude = locationCoordinate.longitude
        location.page = 1
        try? dataController.viewContext.save()
    }

    // MARK: - MKMapViewDelegate

    // Creates the pin for the annotation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }

    // This delegate method is implemented to respond to taps on the info button on the callout
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let pinView = view as! MKPinAnnotationView
            let annotation = pinView.annotation
            let location = annotation?.coordinate
            // Do a segue here to the photo gallery page
            let photoAlbumViewController = storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
            
            // Set the selected pin's location for MapView on the Photo Album View
            if let locationManagedObject = getLocation(location!) {
                photoAlbumViewController.location = locationManagedObject
                photoAlbumViewController.dataController = dataController
                self.navigationController?.pushViewController(photoAlbumViewController, animated: true)
            }
        }
    }
    
    func getLocation(_ location: CLLocationCoordinate2D) -> Location? {
        // Retrieve the location from the database
        let fetchLocationRequest: NSFetchRequest<Location> = Location.fetchRequest()
        let predicate = NSPredicate(format: "latitude == %lf", location.latitude as Double)
        fetchLocationRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        fetchLocationRequest.sortDescriptors = [sortDescriptor]

        if let locationResults = try? dataController.viewContext.fetch(fetchLocationRequest) {
            if locationResults.count == 0 {
                return nil
            }
            return locationResults[0]
        }
        return nil
    }
}
