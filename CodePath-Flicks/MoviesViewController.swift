//
//  MoviesTableViewController.swift
//  CodePath-Flicks
//
//  Created by Ernest on 10/14/16.
//  Copyright © 2016 Purpleblue Pty Ltd. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD
import SwiftyJSON

class MoviesViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var networkErrorView: UIView!
    
    // Store some data
    var endpoint : String = "now_playing"
    var movies : [NSDictionary] = []
    var pageNo : Int = 1
    var genres : Dictionary<Int, String> = [:]
    var viewType = "list"
    var selectedIndexPath : IndexPath = []
    
    // Infinity Load
    var isMoreDataLoading = false
    var loadingMoreView:InfiniteScrollActivityView?

    // Search Bar
    lazy var searchBar:UISearchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 340, height: 20))
    
    // Refresh Control -- if using TableViewController then this is not needed because it's already embedded into UITableView
    let refreshControl = UIRefreshControl()
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.barTintColor = UIColor.white
        tabBarController?.tabBar.barTintColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("endpoint: \(endpoint)")
        
        // Add SearchBar to NavigationBar
        searchBar.placeholder = "Search"
        navigationItem.titleView = searchBar
        searchBar.delegate = self
        
        loadViewType()
        
        // For each view controller that is pushing
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MoviesViewController.loadViewType),
                                               name: NSNotification.Name(rawValue: "com.purpleblue.CodePath-Flicks.loadViewType"),
                                               object: nil)
    }
    
    func loadViewType() {
        let defaults = UserDefaults.standard
        if (defaults.object(forKey: "flicks_view_type") != nil) {
            viewType = (defaults.object(forKey: "flicks_view_type") as! Int! == 1) ? "grid" : "list"
        }
        print("viewType: \(viewType)")
        if (viewType == "list") {
            tableView.isHidden = false
            collectionView.isHidden = true;
            
            // Table View
            tableView.dataSource = self
            tableView.delegate = self
            
            // Only when table is empty
            tableView.emptyDataSetSource = self
            tableView.emptyDataSetDelegate = self
            
            // Adding Pull-to-Refresh
            // Ref: https://guides.codepath.com/ios/Table-View-Guide#adding-pull-to-refresh
            refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
            // add refresh control to table view
            tableView.insertSubview(refreshControl, at: 0)
            
            // Set up Infinite Scroll loading indicator
            // Ref: https://guides.codepath.com/ios/Table-View-Guide#adding-infinite-scroll
            let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
            loadingMoreView = InfiniteScrollActivityView(frame: frame)
            loadingMoreView!.isHidden = true
            tableView.addSubview(loadingMoreView!)
            
            var insets = tableView.contentInset;
            insets.bottom += InfiniteScrollActivityView.defaultHeight;
            tableView.contentInset = insets
            
            // Remove the separator inset
            // Ref: https://guides.codepath.com/ios/Table-View-Guide#how-do-you-remove-the-separator-inset
            tableView.separatorInset = UIEdgeInsets.zero
            
            // A little trick for removing the cell separators
            tableView.tableFooterView = UIView()
        } else {
            tableView.isHidden = true
            collectionView.isHidden = false;
            
            // Collection View
            collectionView.dataSource = self
            collectionView.delegate = self
        }
        
        // Load Movie Genres from Local
        loadMovieGenres()
        
        // Load data from API
        loadData(query: "", usePaging: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Data
    
    func loadMovieGenres() {
        if let path = Bundle.main.path(forResource: "MovieGenres", ofType: "json") {
            do {
                let data = try NSData(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions.mappedIfSafe)
                let jsonObj = JSON(data: data as Data)
                if jsonObj != JSON.null {
                    //print("jsonData:\(jsonObj)")
                    for (_, subJson) in jsonObj["genres"] {
                        //print(subJson["id"].int!)
                        genres[subJson["id"].int!] = subJson["name"].string
                    }
                } else {
                    print("Could not get json from file, make sure that file contains valid json.")
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } else {
            print("Invalid filename/path.")
        }
    }
    
    func getMovieGenres(genreIds: [Int]) -> String {
        var genresDelimited = ""
        // Convert list of Int into String of genres
        for genreId in genreIds {
            //print(genreId)
            //print(genres[genreId]!)
            genresDelimited = String("\(genresDelimited)\(genres[genreId]!), ")
        }
        
        if (genresDelimited.characters.count > 0) {
            // Remove , at the end
            let endIndex = genresDelimited.index(genresDelimited.endIndex, offsetBy: -2) // ", "
            return genresDelimited.substring(to: endIndex)
        } else {
            return ""
        }
    }
    
    func loadData(query: String, usePaging: Bool) {
        // Source: https://api.themoviedb.org/3/movie/now_playing?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed
        
        var url = ""
        if (query.characters.count > 0) {
            url = String("\(Constants.apiBaseUrl)search/movie?query=\(query)&api_key=\(Constants.apiKey)")
        } else {
            if (usePaging && self.viewType == "list") { // Let's infinity scroll
                pageNo = pageNo + 1
            }
            url = String("\(Constants.apiBaseUrl)movie/\(endpoint)?api_key=\(Constants.apiKey)&page=\(pageNo)")
        }
        print("Calling API URL: \(url)")
        //let escapedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        let request = URLRequest(url: URL(string:url)!)
        
        // Configure session so that completion handler is executed on main UI thread
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        // Ref: http://guides.codepath.com/ios/Showing-a-progress-HUD
        // Ref: https://github.com/jdg/MBProgressHUD
        // Display HUD right before the request is made
        //MBProgressHUD.showAdded(to: self.view, animated: true)
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = (query.characters.count > 0) ? "Searching" : "Loading"
        
        let task : URLSessionDataTask = session.dataTask(with: request,completionHandler: { (dataOrNil, response, error) in
            if let data = dataOrNil {
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options:[]) as? NSDictionary {
                    NSLog("response: \(responseDictionary)")
                    
                    if (usePaging && self.pageNo > 1 && self.viewType == "list") { // Let's infinity scroll
                        self.movies.append(contentsOf: responseDictionary.value(forKeyPath: "results") as! [NSDictionary])
                    } else {
                        self.movies = (responseDictionary.value(forKeyPath: "results") as! [NSDictionary]?)!
                    }
                    
                    // Reload the tableView now that there is new data
                    if (self.viewType == "list") {
                        // Update flag
                        self.isMoreDataLoading = false
                        
                        // Stop the loading indicator
                        self.loadingMoreView!.stopAnimating()
                        
                        self.tableView.reloadData()
                    } else {
                        self.collectionView.reloadData()
                    }
                    
                    // Tell the refreshControl to stop spinning
                    self.refreshControl.endRefreshing()
                    
                    // Hide HUD once the network request comes back (must be done on main UI thread)
                    //MBProgressHUD.hide(for: self.view, animated: true)
                    loadingNotification.hide(animated: true)
                    
                    self.showHideNetworkError(hasError: false)
                }
                
                if ((error) != nil) {
                    print(error)
                    
                    self.showHideNetworkError(hasError: true)
                }
            }
        });
        task.resume()
    }
    
    // Makes a network request to get updated data
    // Updates the tableView with the new data
    // Hides the RefreshControl
    func refreshControlAction(refreshControl: UIRefreshControl) {
        // Load data from API
        loadData(query: "", usePaging: false)
    }
    
    func showHideNetworkError(hasError: Bool) {
        if (hasError) {
            // Show View that network connectivity is out
            self.networkErrorView.isHidden = false
            self.networkErrorView.frame.size.height = 30
        } else {
            // Account for refresh where network is up but view still showing
            // TODO: Move to something better which actively monitors connections
            if (!self.networkErrorView.isHidden) {
                // Hide View that network connectivity is out
                self.networkErrorView.isHidden = true
                self.networkErrorView.frame.size.height = 0
            }
        }
    }
    
    // MARK: - Table view data source & delegates
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "com.purpleblue.codepath-flicks.MovieTableViewCell", for: indexPath) as! MovieTableViewCell
        
        let movie = (self.movies[indexPath.row]) as NSDictionary
        
        cell.titleLabel.text = movie.value(forKeyPath: "original_title") as! String?

        let genres = movie.value(forKeyPath: "genre_ids") as? [Int]
        cell.genresLabel.text = (genres != nil) ? self.getMovieGenres(genreIds: genres!) : ""
        
        cell.overviewTextView.text = movie.value(forKeyPath: "overview") as! String?
        
        // Note the use of key path inc @firstObject since .url is a list when consumed
        
        if let posterPath = movie["poster_path"] as? String {
            let posterUrl = NSURL(string: Constants.posterBaseUrl + posterPath)
            //cell.photoImageView.setImageWith(posterUrl! as URL)
            
            // Fading in an Image Loaded from the Network
            // https://guides.codepath.com/ios/Working-with-UIImageView#fading-in-an-image-loaded-from-the-network
            let imageRequest = NSURLRequest(url: posterUrl as! URL)
            cell.photoImageView.setImageWith(
                imageRequest as URLRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        print("Image was NOT cached, fade in image")
                        cell.photoImageView.alpha = 0.0
                        cell.photoImageView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.photoImageView.alpha = 1.0
                        })
                    } else {
                        print("Image was cached so just update the image")
                        cell.photoImageView.image = image
                    }
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    print("Image failed with error = \(error)")
                    // do something for the failure condition
                    cell.photoImageView.image = UIImage.init(named: "kraken-failure")
            })
        }
        else {
            print("Image not found in JSON")
            // No poster image. Can either set to nil (no image) or a default movie poster image
            // that you include as an asset
            cell.photoImageView.image = UIImage.init(named: "kraken-failure")
        }
        
        // Customizing the cell selection effect
        // http://guides.codepath.com/ios/Table-View-Guide#customizing-the-cell-selection-effect
        // Use a red color when the user selects the cell
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(netHex:Constants.cellSelectedColor)
        cell.selectedBackgroundView = backgroundView
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count // new school: posts.count ?? 0 vs. old school: (posts ? posts.count : 0)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get rid of the gray selection effect by deselecting the cell with animation
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        selectedIndexPath = indexPath
        
        self.performSegue(withIdentifier: "MovieDetailSegue", sender: self)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print(sender) // MovieDetailSegue
        
        // Get a reference to the PhotoDetailsViewController
        let destinationViewController = segue.destination as! MovieDetailViewController
        
        /*
        // Get the indexPath of the selected photo
        let indexPath = (self.viewType == "list") ?
            tableView.indexPath(for: sender as! UITableViewCell!) :
            collectionView.indexPath(for: sender as! UICollectionViewCell!)
        print("prepare.indexPath: \(indexPath)")
         */
        
        // Pass the image through
        destinationViewController.movie = (movies[(selectedIndexPath.row)])
    }
    
    // MARK: - Search Bar
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {

    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        
        // Stop doing the search stuff
        // and clear the text in the search bar
        searchBar.text = ""
        
        // Remove focus from the search bar.
        searchBar.endEditing(true)
        
        // Load data from API
        loadData(query: "", usePaging: false) // Default mode
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //print(searchBar.text)
        
        // Load data from API
        loadData(query: searchBar.text!, usePaging: false) // Search mode
    }
    
    // http://shrikar.com/swift-ios-tutorial-uisearchbar-and-uisearchbardelegate/
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.showsCancelButton = true
        
        //print(searchText)
        
        // Load data from API
        //loadData(refreshControl: refreshControl!, query: searchText as NSString)
        
        /*
        filtered = (movies?.filter({ (text) -> Bool in
            let tmp: NSString = text
            let range = tmp.rangeOfString(searchText, options: NSString.CompareOptions.CaseInsensitiveSearch)
            return range.location != NSNotFound
        }))!
        if(filtered.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.tableView.reloadData()
         */
    }
    
    // MARK: - DZNEmptyDataSet
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Whoops.. Nothing here"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Try Searching again please."
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "kraken-pb-eyes-colored-s")
    }
    
    /*
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> NSAttributedString? {
        let str = "Random Demo Search"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.callout)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTap button: UIButton) {
        let query = "FightClub"
        
        // Load data
        loadData(query: query)
        
        // Stop doing the search stuff
        // and clear the text in the search bar
        searchBar.text = query
        
        // Remove focus from the search bar.
        searchBar.endEditing(true)
        
        /*
        let ac = UIAlertController(title: "Button tapped!", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Hurray", style: .default))
        present(ac, animated: true)
         */
    }
    */
    
    // MARK: - Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count 
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "com.purpleblue.codepath-flicks.MovieCollectionViewCell", for: indexPath as IndexPath) as! MovieCollectionViewCell

        let movie = self.movies[indexPath.row]
        
        if let posterPath = movie["poster_path"] as? String {
            let posterBaseUrl = "http://image.tmdb.org/t/p/w500"
            let posterUrl = NSURL(string: posterBaseUrl + posterPath)
            //cell.photoImageView.setImageWith(posterUrl! as URL)
            
            // Fading in an Image Loaded from the Network
            // https://guides.codepath.com/ios/Working-with-UIImageView#fading-in-an-image-loaded-from-the-network
            let imageRequest = NSURLRequest(url: posterUrl as! URL)
            cell.photoImageView.setImageWith(
                imageRequest as URLRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        print("Image was NOT cached, fade in image")
                        cell.photoImageView.alpha = 0.0
                        cell.photoImageView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.photoImageView.alpha = 1.0
                        })
                    } else {
                        print("Image was cached so just update the image")
                        cell.photoImageView.image = image
                    }
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // do something for the failure condition
            })
        }
        else {
            // No poster image. Can either set to nil (no image) or a default movie poster image
            // that you include as an asset
            cell.photoImageView.image = nil
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        
        self.performSegue(withIdentifier: "MovieDetailSegue", sender: self)
    }
    
    // MARK: - Scroll view delegates
    
    // Add a loading view to your view controller
    // https://guides.codepath.com/ios/Table-View-Guide#add-a-loading-view-to-your-view-controller
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Handle scroll behavior here
        
        if (!isMoreDataLoading) {
            // Calculate the position of one screen length before the bottom of the results
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging) {
                isMoreDataLoading = true
                
                // Update position of loadingMoreView, and start loading indicator
                let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                // ... Code to load more results ...
                loadData(query: "", usePaging: true)
            }
        }
    }
}
