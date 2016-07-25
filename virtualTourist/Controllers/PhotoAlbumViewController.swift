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

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
        setReqion()
        setCollectionViewFlowLayout()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let photos = fetchedResultsController?.fetchedObjects as? [Photo] {
            if photos.isEmpty {
                
                searchByLatLong()
            }
        }else{
            
        }

    }
    
    // MARK: - Methods
    @IBAction func newCollection(sender: AnyObject) {
        print("se presionó la búsqueda de una nueva collection")
        if selectedIndexes.isEmpty {
            deleteAllPhotos()
            searchByLatLong()
        } else {
            deleteSelectedPhotos()
        }
        
    }
    
    
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
        activityIndicator.startAnimating()
        if let pin = pin {
            FlickrClient.sharedInstance().getPhotosForPin(pin, completionPhotos: { (success, photoURLs, errorString) in
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


// MARK:  - Delegate
// code extract from Stackoerflow:
// http://stackoverflow.com/questions/12656648/uicollectionview-performing-updates-using-performbatchupdates
// answer answered Mar 5 '15 at 12:45 For Plot
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate{
    
//    func controllerWillChangeContent(controller: NSFetchedResultsController) {
//        blockOperations.removeAll(keepCapacity: false)
//    }
//    
//    func controller(controller: NSFetchedResultsController,
//                    didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
//                                     atIndex sectionIndex: Int,
//                                             forChangeType type: NSFetchedResultsChangeType) {
//        
//        let indexSet = NSIndexSet(index: sectionIndex)
//        
//        switch type{
//        case .Insert:
//            print("Insert Section: \(sectionIndex)")
//            
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.insertSections( indexSet )
//                    }
//                    })
//            )
//        case .Update:
//            print("Update Section: \(sectionIndex)")
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.reloadSections( indexSet )
//                    }
//                    })
//            )
//        case .Delete:
//            print("Delete Section: \(sectionIndex)")
//            
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.deleteSections( indexSet )
//                    }
//                    })
//            )
//        default:
//            break
//        }
//        
//    }
//    
//    
//    func controller(controller: NSFetchedResultsController,
//                    didChangeObject anObject: AnyObject,
//                                    atIndexPath indexPath: NSIndexPath?,
//                                                forChangeType type: NSFetchedResultsChangeType,
//                                                              newIndexPath: NSIndexPath?) {
//        
//        switch type {
//        case .Insert:
//            print("Insert Object: \(newIndexPath)")
//            
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
//                    }
//                    })
//            )
//        case .Update:
//            print("Update Object: \(indexPath)")
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
//                    }
//                    })
//            )
//        case .Move:
//            print("Move Object: \(indexPath)")
//            
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
//                    }
//                    })
//            )
//        case .Delete:
//            print("Delete Object: \(indexPath)")
//            
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.deleteItemsAtIndexPaths([indexPath!])
//                    }
//                    })
//            )
//        }
//        
//    }
//    
//    func controllerDidChangeContent(controller: NSFetchedResultsController) {
//        collectionView!.performBatchUpdates({ () -> Void in
//            for operation: NSBlockOperation in self.blockOperations {
//                operation.start()
//            }
//            }, completion: { (finished) -> Void in
//                self.blockOperations.removeAll(keepCapacity: false)
//        })
//    }
    
    
    
    ////////////////////////////
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            print("Insert an item")
            // Here we are noting that a new Color instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            // Here we are noting that a Color instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            // We don't expect Color instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        default:
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
