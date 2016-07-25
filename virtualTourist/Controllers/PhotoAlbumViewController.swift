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
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    
    // MARK: Properties
    let reuseIdentifier = "cellPhoto" // identifier in collection view
    var pin: Pin?
    var stack: CoreDataStack!

    var fetchedResultsController: NSFetchedResultsController? {
        didSet{
            // whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView?.reloadData()
        }
    }

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        newCollectionButton.enabled = false
        stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
        setReqion()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let photos = fetchedResultsController?.fetchedObjects as? [Photo] {
            if photos.isEmpty {
                searchByLatLong()
            }else{
                newCollectionButton.enabled = true
            }
        }else{
            newCollectionButton.enabled = true
        }

    }
    
    // Layout the collection view
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: - Methods
    @IBAction func newCollection(sender: AnyObject) {
        if selectedIndexes.isEmpty {
            deleteAllPhotos()
            searchByLatLong()
        } else {
            deleteSelectedPhotos()
        }
        
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
        activityIndicator.startAnimating()
        if let pin = pin {
            FlickrClient.sharedInstance().getPhotosForPin(pin, completionPhotos: { (success, photoURLs, errorString) in
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.newCollectionButton.enabled = true
                }
                var photos = [Photo]()
                
                if success {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.activityIndicator.stopAnimating()
                        
                        let urls  = photoURLs["url_m"] as! [String]
                        for url in urls {
                            
                            let picture = Photo(url: url, context: self.stack.context)
                            
                            picture.pin = self.pin
                            
                            photos.append(picture)
                        }
                        
                        self.stack.save()
                        
                        self.noImagesLabel.hidden = photos.isEmpty ? false : true

                    }

                }else{
                    dispatch_async(dispatch_get_main_queue()) {
                        self.activityIndicator.stopAnimating()
                        self.noImagesLabel.hidden = photos.isEmpty ? false : true
                    }
                }
                
            })
        }
        else{
            newCollectionButton.enabled = true
            activityIndicator.stopAnimating()
            noImagesLabel.hidden = false
        }
        
    }
    
    func deleteAllPhotos() {

        for photo in fetchedResultsController!.fetchedObjects as! [Photo] {
            stack.context.deleteObject(photo)
        }
    }
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController?.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            stack.context.deleteObject(photo)
        }
        
        selectedIndexes = [NSIndexPath]()
        updateBottomButton()
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            newCollectionButton.title = "Remove Selected Colors"
        } else {
            newCollectionButton.title = "New Collection"
        }
    }

}

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController{
            return (fc.sections?.count)!
        }else {
            return 1
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        // Get the photo
        let photo = fetchedResultsController?.objectAtIndexPath(indexPath) as! Photo
        
        // Get the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        // Sync note -> cell
        cell.setPhotoCell(photo)
        
        if selectedIndexes.indexOf(indexPath) != nil {
            cell.photoImageView.alpha = 0.5
        } else {
            cell.photoImageView.alpha = 1
        }
        
        // Return the cell
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        if selectedIndexes.indexOf(indexPath) != nil {
            cell.photoImageView.alpha = 0.5
        } else {
            cell.photoImageView.alpha = 1
        }
        
        // And update the buttom button
        updateBottomButton()
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


// MARK:  - Fetched Results Controller Delegate
// code extract from CollorCollection Udacity:
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate{

    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:

            deletedIndexPaths.append(indexPath!)
            break
        case .Update:

            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
}

