//
//  MovieDetailViewController.swift
//  CodePath-Flicks
//
//  Created by Ernest on 10/14/16.
//  Copyright © 2016 Purpleblue Pty Ltd. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var detailView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var popularityLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var homepageTextView: UITextView!
    
    var movie: NSDictionary = [:]
    var movieSupplemental: NSDictionary = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("movie: \(movie)")
        
        let movieId = movie.value(forKeyPath: "id") as! Int
        loadSupplementalData(movieId: movieId)
        populateData()
        
        // Scroll View Guide
        // http://guides.codepath.com/ios/Scroll-View-Guide
        let contentWidth = scrollView.bounds.width
        let contentHeight = scrollView.bounds.height * 3
        scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
        
        /*
        // Ref: http://guides.codepath.com/ios/Using-Gesture-Recognizers
        // The didTap: method will be defined in Step 3 below.
        let tapGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didDrag(sender:)))
        
        // Drag view up
        detailView.isUserInteractionEnabled = true
        detailView.addGestureRecognizer(tapGestureRecognizer)
         */
        
        let titleLabel = UILabel()
        /*
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(1)
        shadow.shadowOffset = CGSize(width: 0, height: 0);
        shadow.shadowBlurRadius = 1;
        */
        let titleText = NSAttributedString(string: movie.value(forKeyPath: "original_title") as! String, attributes: [
            NSFontAttributeName : UIFont(name: "OpenSans", size: 18)!,
            NSForegroundColorAttributeName : UIColor.darkText,
            //NSShadowAttributeName : shadow
            ])
        
        titleLabel.attributedText = titleText
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
    }
    
    func loadAdditionalMovieData() {
        // TODO
        // https://api.themoviedb.org/3/movie/550?api_key=5853ae156b66820ac02c1cbbaca0a148
        //  = movie.value(forKeyPath: "popularity") as! String?
    }
    
    // MARK: - Data
    
    func loadSupplementalData(movieId: Int) {
        // Source: https://api.themoviedb.org/3/movie/550?api_key=5853ae156b66820ac02c1cbbaca0a148
        
        let url = String("\(Constants.apiBaseUrl)movie/\(movieId)?api_key=\(Constants.apiKey)")
        print("Calling API URL: \(url)")
        
        let request = URLRequest(url: URL(string:url!)!)
        
        // Configure session so that completion handler is executed on main UI thread
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(with: request,completionHandler: { (dataOrNil, response, error) in
            if let data = dataOrNil {
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options:[]) as? NSDictionary {
                    NSLog("response: \(responseDictionary)")
                    
                    self.movieSupplemental = responseDictionary
                    
                    // Update view with new data
                    let popularity = self.movieSupplemental.value(forKeyPath: "popularity") as! Double
                    self.popularityLabel.text = String("\(popularity.formatWithDecimalPlaces(decimalPlaces: 2))")
                    
                    let runTimeMins = self.movieSupplemental.value(forKeyPath: "runtime")
                    self.durationLabel.text = String("\(runTimeMins!) mins")
                    
                    if let homepagePath = self.movieSupplemental["homepage"] as? String {
                        self.homepageTextView.text = homepagePath
                    } else {
                        self.homepageTextView.text = ""
                    }
                }
            }
        });
        task.resume()
    }
    
    func populateData() {
        titleLabel.text = movie.value(forKeyPath: "original_title") as! String?
        
        // Type convert String to Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let releaseDate = dateFormatter.date(from: movie.value(forKeyPath: "release_date") as! String)
        
        // Pretty format
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = .none
        
        let dateString = formatter.string(from: releaseDate!)
        releaseDateLabel.text = String("\(dateString)")
        
        overviewLabel.text = movie.value(forKeyPath: "overview") as! String?
        
        // Loading a Low Resolution Image followed by a High Resolution Image
        // https://guides.codepath.com/ios/Working-with-UIImageView#loading-a-low-resolution-image-followed-by-a-high-resolution-image
        let backdropExists = movie["backdrop_path"] != nil // eek! => "backdrop_path" = "<null>";
        if (backdropExists) {
            let smallImageRequest = NSURLRequest(url: NSURL(string: String("\(Constants.secureBaseUrl)\(Constants.imageBackdropSizeSmall)\(movie["backdrop_path"]!)")) as! URL)
            let largeImageRequest = NSURLRequest(url: NSURL(string: String("\(Constants.secureBaseUrl)\(Constants.imageBackdropSizeLarge)\(movie["backdrop_path"]!)")) as! URL)
            
            photoImageView.setImageWith(
                smallImageRequest as URLRequest,
                placeholderImage: nil,
                success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in
                    
                    // smallImageResponse will be nil if the smallImage is already available
                    // in cache (might want to do something smarter in that case).
                    self.photoImageView.alpha = 0.0
                    self.photoImageView.image = smallImage;
                    
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        
                        self.photoImageView.alpha = 1.0
                        
                        }, completion: { (sucess) -> Void in
                            
                            // The AFNetworking ImageView Category only allows one request to be sent at a time
                            // per ImageView. This code must be in the completion block.
                            self.photoImageView.setImageWith(
                                largeImageRequest as URLRequest,
                                placeholderImage: smallImage,
                                success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                                    
                                    self.photoImageView.image = largeImage;
                                    
                                },
                                failure: { (request, response, error) -> Void in
                                    print("Image failed with error = \(error)")
                                    // do something for the failure condition of the large image request
                                    // possibly setting the ImageView's image to a default image
                                    self.photoImageView.image = UIImage.init(named: "kraken-failure")
                            })
                    })
                },
                failure: { (request, response, error) -> Void in
                    print("Image not found in JSON")
                    // do something for the failure condition
                    // possibly try to get the large image
                    self.photoImageView.image = UIImage.init(named: "kraken-failure")
            })
            
        } else {
            self.photoImageView.image = UIImage.init(named: "kraken-failure")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Gestures
    
    func didDrag(sender: UIPanGestureRecognizer) {
        let location = sender.location(in: view)
        print(location)
        // User tapped at the point above. Do something with that if you want.
        
        // Ref: http://guides.codepath.com/ios/Using-Modal-Transitions#triggering-the-transition-manually
        //performSegue(withIdentifier: "fullScreenSegue", sender: nil)
        
        // These values depends on the positioning of your element
        //let left = CGAffineTransform(translationX: -300, y: 0)
        //let right = CGAffineTransform(translationX: 300, y: 0)
        let top = CGAffineTransform(translationX: 0, y: -200)
        
        UIView.animate(withDuration: 1.4, delay: 0, usingSpringWithDamping: 2, initialSpringVelocity: 6, animations: {
            // Add the transformation in this block
            // self.container is your view that you want to animate
            self.detailView.transform = top
            }, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get a reference to the PhotoDetailsViewController
        //let destinationViewController = segue.destination as! FullScreenPhotoViewController
        
        // Pass the image through
        //destinationViewController.photoImage = photoImageView.image
    }

}
