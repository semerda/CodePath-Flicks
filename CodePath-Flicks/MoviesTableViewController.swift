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

class MoviesTableViewController: UITableViewController, UISearchBarDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var networkErrorView: UIView!
    
    var endpoint : String = "now_playing"
    
    var movies : [NSDictionary]?
    var genres : Dictionary<Int, String> = [:]

    lazy var searchBar:UISearchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 340, height: 20))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("endpoint: \(endpoint)")
        
        // Add SearchBar to NavigationBar
        searchBar.placeholder = "Search"
        navigationItem.titleView = searchBar
        searchBar.delegate = self
        
        // Adding Pull-to-Refresh
        // Ref: https://guides.codepath.com/ios/Table-View-Guide#adding-pull-to-refresh
        refreshControl?.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
        // add refresh control to table view
        //tableView.insertSubview(refreshControl!, at: 0)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Load Movie Genres from Local
        loadMovieGenres()
        
        // Load data from API
        loadData(query: "")
        
        // Remove the separator inset
        // Ref: https://guides.codepath.com/ios/Table-View-Guide#how-do-you-remove-the-separator-inset
        self.tableView.separatorInset = UIEdgeInsets.zero
        
        // For each view controller that is pushing
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
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
                    print("jsonData:\(jsonObj)")
                    
                    for (_, subJson) in jsonObj["genres"] {
                        //print(subJson["id"].int!)
                        genres[subJson["id"].int!] = subJson["name"].string
                    }
                    
                    //if let responseDictionary = try! JSONSerialization.jsonObject(with: data as Data, options:[]) as? NSDictionary {
                    //    genres = responseDictionary.value(forKeyPath: "genres") as? [NSDictionary]
                    //    print("genres: \(genres)")
                    //}
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
            print(genres[genreId]!)
            //genresDelimited = ((genres[genreId] as? String)! + genres[genreId]! as? String)! + ", "
            genresDelimited = String("\(genresDelimited)\(genres[genreId]!), ")
        }
        
        if (genresDelimited.characters.count > 0) {
            // Remove , at the end
            let endIndex = genresDelimited.index(genresDelimited.endIndex, offsetBy: -2) // ", "
            //print(endIndex)
            //genresDelimited.remove(at: genresDelimited.index(before: endIndex))
            //print("genresDelimited: \(genresDelimited)")
            
            return genresDelimited.substring(to: endIndex)
        } else {
            return ""
        }
    }
    
    func loadData(query: String) {
        // Source: https://api.themoviedb.org/3/movie/now_playing?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed
        
        var url = ""
        if (query.characters.count > 0) {
            url = String("\(Constants.apiBaseUrl)search/movie?query=\(query)&api_key=\(Constants.apiKey)")
        } else {
            url = String("\(Constants.apiBaseUrl)movie/\(endpoint)?api_key=\(Constants.apiKey)")
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
                    
                    self.movies = responseDictionary.value(forKeyPath: "results") as? [NSDictionary]
                    
                    /*
                     // Update flag
                     self.isMoreDataLoading = false
                     
                     // Stop the loading indicator
                     self.loadingMoreView!.stopAnimating()
                     */
                    // Reload the tableView now that there is new data
                    self.tableView.reloadData()
                    
                    // Tell the refreshControl to stop spinning
                    self.refreshControl?.endRefreshing()
                    
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
        loadData(query: "")
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "com.purpleblue.codepath-flicks.MovieTableViewCell", for: indexPath) as! MovieTableViewCell
        let movie = self.movies?[indexPath.row]
        
        cell.titleLabel.text = movie?.value(forKeyPath: "original_title") as! String?

        let genres = movie?.value(forKeyPath: "genre_ids") as? [Int]
        cell.genresLabel.text = (genres != nil) ? self.getMovieGenres(genreIds: genres!) : ""
        
        cell.overviewTextView.text = movie?.value(forKeyPath: "overview") as! String?
        
        // Note the use of key path inc @firstObject since .url is a list when consumed
        
        if let posterPath = movie?["poster_path"] as? String {
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
        
        // Customizing the cell selection effect
        // http://guides.codepath.com/ios/Table-View-Guide#customizing-the-cell-selection-effect
        // Use a red color when the user selects the cell
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(netHex:Constants.cellSelectedColor)
        cell.selectedBackgroundView = backgroundView
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies?.count ?? 0 // old school: (posts ? posts.count : 0)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get rid of the gray selection effect by deselecting the cell with animation
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print(sender) // MovieDetailSegue
        
        // Get a reference to the PhotoDetailsViewController
        let destinationViewController = segue.destination as! MovieDetailViewController
        
        // Get the indexPath of the selected photo
        let indexPath = tableView.indexPath(for: sender as! UITableViewCell)
        //print("indexPath: \(indexPath)")
        
        // Pass the image through
        destinationViewController.movie = (movies?[(indexPath?.row)!])!
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
        loadData(query: "") // Default mode
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //print(searchBar.text)
        
        // Load data from API
        loadData(query: searchBar.text!) // Search mode
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
}
