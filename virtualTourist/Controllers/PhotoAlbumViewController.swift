//
//  PhotoAlbumViewController.swift
//  virtualTourist
//
//  Created by Rodrigo Astorga on 27-06-16.
//  Copyright © 2016 Rodrigo Astorga. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    // MARK: Properties
    let reuseIdentifier = "cellPhoto" // identifier in collection view
    var pin: Pin?
    var stack: CoreDataStack!
    var blockOperations: [NSBlockOperation] = []
    
    var fetchedResultsController: NSFetchedResultsController? {
        didSet{
            // whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView?.reloadData()
        }
    }

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
        setReqion()
        setCollectionViewFlowLayout()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if fetchedResultsController?.fetchedObjects?.count == 0 {
            searchByLatLong()
        }
//        if fetchedResultsController.fetchedObjects?.count > 0 {
//        if let pin = pin,
//            let photos = pin.photos{
//            if photos.array.isEmpty {
//                searchByLatLong()
//            }
//        }else{
//            searchByLatLong()
//        }
    }
    
    // MARK: - Methods
    private func setCollectionViewFlowLayout(){
        let space: CGFloat = 3.0
        let dimensionWidth = (view.frame.size.width - (2 * space)) / 3.0
        
        collectionViewFlowLayout.minimumInteritemSpacing = space
        collectionViewFlowLayout.minimumLineSpacing = space
        collectionViewFlowLayout.itemSize = CGSizeMake(dimensionWidth, dimensionWidth)
    }
    
    private func setReqion() {
        if let pin = pin {
            
            let centerCoordinate = pin.coordinate
            
            let longitudeDelta = 0.45
            let latitudeDelta = 0.45
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let region = MKCoordinateRegion(center: centerCoordinate, span: span)
            
            mapView.setRegion(region, animated: false)
            mapView.addAnnotation(pin)
        }
    }
    
    private func searchByLatLong() {
        if let pin = pin {
            FlickrClient.sharedInstance().getPhotosByLocation(pin, completionPhotos: { (success, photoURLs, errorString) in
                if success {
                    var photos = [Photo]()
                    dispatch_async(dispatch_get_main_queue()) {
                        for url in photoURLs {
                            
                            let picture = Photo(url: url, context: self.stack.context)
                            
                            picture.pin = self.pin
                            
                            photos.append(picture)
                        }
                        self.downloadImage(photos)
                    }
                    
//                    let photos = photoURLs.map({ (url: String) -> Photo in
//                        
//                        let photo = Photo(url: url, context: self.stack.context)
//                        
//                        photo.pin = self.pin
//                        
//                        return photo
//                    })
                    
                    
                }
                
            })
        }
        
//            displayImageFromFlickrBySearch(methodParameters)
//        }
//        else {
//            setUIEnabled(true)
//            photoTitleLabel.text = "Lat should be [-90, 90].\nLon should be [-180, 180]."
//        }
    }
    
    func downloadImage(photos: [Photo]){
        
        for photo in photos {
            if photo.image == nil {
                FlickrClient.sharedInstance().downloadImage(photo.url!, completion: { (imageData, errorString) in

                    dispatch_async(dispatch_get_main_queue()) {
                        if let imageData = imageData {
                            photo.imageData = imageData
                        }
                    }
                    
                })
            }
        }
        
//        stack.performBackgroundBatchOperation { (workerContext) in
//            
//            for photo in photos {
//                if photo.image == nil {
//                    FlickrClient.sharedInstance().downloadImage(photo.url!, completion: { (imageData, errorString) in
//                        if let imageData = imageData {
//                            photo.imageData = imageData
//                        }
//                        
//                    })
//                }
//            }
//        }
    }
    
    

}

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        // Get the photo
        let photo = fetchedResultsController?.objectAtIndexPath(indexPath) as! Photo
        
        // Get the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        // Sync note -> cell
        cell.setPhotoCell(photo)
        
        // Return the cell
        return cell
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController{
            return (fc.sections?.count)!
        }else {
            return 1
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController{
            return (fc.sections![section].numberOfObjects)
        }else {
            return 1
        }
    }

}

// MARK: - Fetches
extension PhotoAlbumViewController{
    
    func executeSearch(){
        if let fc = fetchedResultsController{
            do{
                try fc.performFetch()
            }catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
                
            }
        }
    }
}


// MARK:  - Delegate
// code extract from Stackoerflow:
// http://stackoverflow.com/questions/12656648/uicollectionview-performing-updates-using-performbatchupdates
// answer answered Mar 5 '15 at 12:45 For Plot
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate{
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        blockOperations.removeAll(keepCapacity: false)
    }
    
    func controller(controller: NSFetchedResultsController,
                    didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                                     atIndex sectionIndex: Int,
                                             forChangeType type: NSFetchedResultsChangeType) {
        
        let indexSet = NSIndexSet(index: sectionIndex)
        
        switch type{
        case .Insert:
            print("Insert Section: \(sectionIndex)")
            
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections( indexSet )
                    }
                    })
            )
        case .Update:
            print("Update Section: \(sectionIndex)")
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections( indexSet )
                    }
                    })
            )
        case .Delete:
            print("Delete Section: \(sectionIndex)")
            
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections( indexSet )
                    }
                    })
            )
        default:
            break
        }
        
    }
    
    
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                                    atIndexPath indexPath: NSIndexPath?,
                                                forChangeType type: NSFetchedResultsChangeType,
                                                              newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            print("Insert Object: \(newIndexPath)")
            
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                    }
                    })
            )
        case .Update:
            print("Update Object: \(indexPath)")
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        case .Move:
            print("Move Object: \(indexPath)")
            
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    }
                    })
            )
        case .Delete:
            print("Delete Object: \(indexPath)")
            
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        }
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: NSBlockOperation in self.blockOperations {
                operation.start()
            }
            }, completion: { (finished) -> Void in
                self.blockOperations.removeAll(keepCapacity: false)
        })
    }
}

///////////// MARK: - Fetched Results Controller Delegate

//var changes: [(NSFetchedResultsChangeType, NSIndexPath)]?
//
//func controllerWillChangeContent(controller: NSFetchedResultsController) {
//    changes = [(NSFetchedResultsChangeType, NSIndexPath)]()
//    
//    print("in controllerWillChangeContent")
//}
//
//func controllerDidChangeContent(controller: NSFetchedResultsController) {
//    
//    print("in controllerDidChangeContent. changes.count: \(changes!.count)")
//    
//    collectionView.performBatchUpdates({() -> Void in
//        for change in self.changes! {
//            switch (change) {
//                
//            case (.Insert, let indexPath):
//                self.collectionView.insertItemsAtIndexPaths([indexPath])
//            case (.Update, let indexPath):
//                self.collectionView.reloadItemsAtIndexPaths([indexPath])
//            case (.Delete, let indexPath):
//                self.collectionView.deleteItemsAtIndexPaths([indexPath])
//            default:
//                break
//            }
//        }
//        }, completion: { (success: Bool) -> Void in
//    })
//}
//
//func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//    
//    switch type{
//    case .Insert:
//        print("bam. insert!")
//        let change = (type, newIndexPath!)
//        changes!.append(change)
//        break
//    case .Delete:
//        print("bam. delete!")
//        let change = (type, indexPath!)
//        changes!.append(change)
//        break
//    case .Update:
//        print("bam. update!")
//        let change = (type, indexPath!)
//        changes!.append(change)
//        break
//    case .Move:
//        print("bam. move!")
//        break
//    }
//}
