//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Mike Allan on 2020-10-18.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {
    
    private let reuseIdentifier = "Cell"
    
    private let itemsPerRow: CGFloat = 3

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var location: Location!
    var page: Int = 1;
    var pages: Int = 1;
    
    var dataController: DataController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Register cell classes
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    
        mapView.setCenter(center, animated: true)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
        
        // Generate a pin
        let currentLocationPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set its coordinates.
        currentLocationPin.coordinate = center
        
        // Add it to the mapView
        mapView.addAnnotation(currentLocationPin)
        
        loadLocationPhotos()
        
        calculateFlowLayoutDimensions()
    }

    func calculateFlowLayoutDimensions() {
        let space: CGFloat = 2.0
        var imagesPerRow:CGFloat = 3.0
        if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
            imagesPerRow = 4.0
        }
        let dimension = (view.frame.size.width - (2 * space)) / imagesPerRow
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    func loadLocationPhotos() {
        print("loadLocationPhotos() invoked")
        if location.photos?.count == 0 {
            print("Getting a new batch of photos")
            if let lat = location?.latitude.description, let long = location?.longitude.description {
                FlickrClient.getPhotos(lat: lat, long: long, page: page, completion: handleNewPhotos)
            }
        }
    }
    
    @IBAction func loadNewPhotos() {
        print("loadNewPhotos() invoked")
        if page < pages {
            page += 1
        }
        else {
            page = 1
        }
        location.page = Int32(page)
        
        // Remove the old photos
        print("Deleting the old photos - number of photos in location is \(location.photos?.count ?? 0)")
        if let locationPhotos = location.photos {
            let photoCount = locationPhotos.count
            for i in 0...photoCount-1 {
                print("Deleting photo number \(i)")
                let photo = locationPhotos.object(at: i)
                //location.removeFromPhotos(at: i)
                dataController.viewContext.delete(photo as! LocationPhoto)
            }
            try? dataController.viewContext.save()
            print("Done deleting old photos! - number of photos in location is \(location.photos?.count ?? 0)")
        }
        
        // Load new photos
        loadLocationPhotos()
    }
    
    func handleNewPhotos(newPhotos:Photos?, error: Error?) {
        print("handleNewPhotos invoked, newPhotos count = \(newPhotos?.photo.count ?? 0)")
        if let error = error {
            showNewPhotosError(message: error.localizedDescription)
        }
        else {
            print("Updating the photos collection in the PhotoAlbumViewController member")
            // Need to do 2 things here
            // 1: Update the photo collection in the Location Managed Object
            savePhotos(newPhotos)
            // 2: Refresh the page with the new photo collection
            DispatchQueue.main.async {
                print("reloading the data")
                self.collectionView.reloadData()
            }
        }
    }
    
    func savePhotos(_ newPhotos:Photos?) {
        if let photos = newPhotos {
            // Add the new photos
            print("Adding the new photos")
            for photo in photos.photo {
                let locationPhoto = LocationPhoto(context: dataController.viewContext)
                locationPhoto.photoId = photo.id
                locationPhoto.photoSecret = photo.secret
                locationPhoto.serverId = photo.server
                location.addToPhotos(locationPhoto)
            }
            try? dataController.viewContext.save()
        }
    }
    
    func showNewPhotosError(message: String) {
        DispatchQueue.main.async {
            let alertVC = UIAlertController(title: "Get New Photos Failed", message: message, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertVC, animated: true)
        }
    }
}

extension PhotoAlbumViewController:  UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var photoCount = location.photos?.count ?? 0
        if photoCount < 1 {
            photoCount = 1
        }
        return photoCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! PhotoCollectionViewCell
        let photoCount = location.photos?.count ?? 0
        if photoCount > 0 {
            let photo = location.photos?.object(at: indexPath.row) as! LocationPhoto
            cell.imageView?.image = UIImage(named: "PlaceholderImage")
            
            if let serverId = photo.serverId, let photoId = photo.photoId, let photoSecret = photo.photoSecret {
                FlickrClient.downloadPhotoImage(serverId: serverId, photoId: photoId, photoSecret: photoSecret) { (data, error) in
                    guard let data = data else {
                        print("Error: \(error?.localizedDescription ?? "(no error description)")")
                        return
                    }
                    DispatchQueue.main.async {
                        let image = UIImage(data: data)
                        cell.imageView?.image = image
                    }
                }
            }
        }
        else {
            let rect = CGRect(x: 0, y: 0, width: collectionView.frame.width, height: collectionView.frame.height)
            let noDataLabel: UILabel = UILabel(frame: rect)
            noDataLabel.text = "No Images"
            noDataLabel.textAlignment = .center
            noDataLabel.textColor = UIColor.gray
            noDataLabel.sizeToFit()

            //let cell = UICollectionViewCell()
            cell.contentView.addSubview(noDataLabel)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = location.photos?.object(at: indexPath.row) as! LocationPhoto
        dataController.viewContext.delete(photo)
        location.removeFromPhotos(at: indexPath.row)
        try? dataController.viewContext.save()
        self.collectionView.reloadData()
    }
}

