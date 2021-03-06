# Project 1 - *Kraken Flicks*

**Kraken Flicks** is a movies app using the [The Movie Database API](http://docs.themoviedb.apiary.io/#).

Time spent: **∞** hours spent in total

## User Stories

The following **required** functionality is completed:

- [x] User can view a list of movies currently playing in theaters. Poster images load asynchronously.
- [x] User can view movie details by tapping on a cell.
- [x] User sees loading state while waiting for the API.
- [x] User sees an error message when there is a network error.
- [x] User can pull to refresh the movie list.

The following **optional** features are implemented:

- [x] Add a tab bar for **Now Playing** and **Top Rated** movies.
- [x] Implement segmented control to switch between list view and grid view.
- [x] Add a search bar.
- [x] All images fade in.
- [x] For the large poster, load the low-res image first, switch to high-res when complete.
- [x] Customize the highlight and selection effect of the cell.
- [x] Customize the navigation bar.

The following **additional** features are implemented:

- [x] Using Custom Fonts - OpenSans.
- [x] Added Genres to Movies list.
- [x] Added Browser to launch Movie Homepage from Movie Detail.
- [x] Added App Icon - Kraken Flicks.
- [x] When image fails, loads the Kraken Failed placeholder image.
- [x] Using NSNotificationCenter to notify when layouts should be updated in ViewController.
- [x] Customized MBProgressHUD so it's explicit/informative between Loading and Searching.
- [x] Added Infinity Scroll.
- [x] Used [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) - a better way to deal with JSON data in Swift.
- [x] Used [DZNEmptyDataSet](https://github.com/dzenbot/DZNEmptyDataSet) - for showing empty datasets whenever the view has no content to display.

## Video Walkthrough

Here's a walkthrough of implemented user stories:

<img src='https://github.com/semerda/CodePath-Flicks/blob/master/Assets/flicks-anim-v1.gif' title='Kraken Flicks Video Walkthrough' width='' alt='Kraken Flicks Video Walkthrough' loop=infinite />

GIF created with [LiceCap](http://www.cockos.com/licecap/).

## Open-source libraries used

- [AFNetworking](https://github.com/AFNetworking/AFNetworking) - a delightful networking framework for iOS, OS X, watchOS, and tvOS.
- [MBProgressHUD](https://github.com/jdg/MBProgressHUD) - an iOS drop-in class that displays a translucent HUD with an indicator and/or labels while work is being done in a background thread.
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) - a better way to deal with JSON data in Swift.
- [DZNEmptyDataSet](https://github.com/dzenbot/DZNEmptyDataSet) - for showing empty datasets whenever the view has no content to display.

## License

Visit [www.ernestsemerda.com](http://www.ernestsemerda.com/)

    Copyright 2016 Ernest Semerda (http://www.ernestsemerda.com/)

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.