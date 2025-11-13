**Group #7 Members:**

- Isaac Thomas

- Daniel Levi

- Austin Nguyen

- Ian Tran

**Instructions for running the code:**

Here’s users you can use to look at existing functionality for feeds and friend system

- Email: <daniellevi@daniel.com>

- Password: 12341234

- Email: [isaac@isaac.com](mailto:isaacthomas@isaac.com)

- Password: 12341234

**Contributions:**

- Daniel Levi (Release: 25%, Overall: 25%)

  - Alpha

    - Login and SignUpPage UI. 

    - userName implementation on SignUpPage

    - Tab Bar Controller and Tab Bar implementation 

      - (Bar at the bottom of the home, profile, map and settings screens)

      - Segues to each respective view controller based on what is tapped on the tab bar.

    - PostPage UI

      - Displays a selected post and its associated information (likes/comments count, the owner of the post, date posted, and location)

    - ProfilePage UI and implementation

      - userName and bioField labels update based on what is stored in Firebase (based on who is currently signed in)

      - Segmented Control that displays a gridOfPosts, mapView, or list of friends, based on what is selected on the segmentedControl

      - Posts/Friends are clickable. 

      - Friends list is connected to Firestore, and when clicked maps to OtherProfilePage(where their profile is displayed)

      - When tapping on a post, you are taken to PostPage, which displays the post that was clicked on. 

    - OtherProfilePage UI and implementation

      - Has all the same implementation as the ProfilePage

  - Beta - 20%

    - EditProfilePage UI and functionality

    - Add Friend and “Friend Check” implementation for profiles.

    - Connecting OtherProfilePage to the selected users' posts/Firebase database.

    - Small Redesign of the UI for the ProfilePage

    - Like Count updates. 

    - Enabled Comments to show who posted them properly. 

    - Altered the code in ProfilePage to update immediately when someone changes their username/bio. 

- Isaac Thomas (Release: 25%, Overall: 30%) 

  - Alpha

    - Home Page UI and Navigation

      - Created base design for the 4 main pages (Home, Profile, Discover, and Settings)

      - Worked with Daniel on Navigation through the Tab Bar Controller

    - FeedViewController, FeedPost, PostTableViewCell

      - Hard-coded functionality right now, will connect to DB to get posts from friends, sort by timestamp, and present on table view

    - Home Screen Feed

      - Created a Table View with a custom prototype cell tied to PostTableViewCell

      - Created UI design on storyboard

    - Add Post View Controller and Functionality

      - Hard Coded right now, will connect to DB to add post to list of posts under the user

  - Beta

    - Connected the feed to the database

    - Implemented “Add Post” functionality with database integration

    - Designed the UI for posts and their comments as part of the comment feature development

    - Recreated the logo and added it to the storyboard

    - Added functionality to remove friends

    - Updated the comment system to use a dedicated Comment data structure for more efficient storage and retrieval

    - Added pull-to-refresh functionality for the feed

    - Modified the home feed to display only friends’ posts

    - Created a new Global Feed page showing all public posts (excluding private accounts), which will be changed to location-based as a stretch goal

    - Made both feed incrementally load instead of having a blank screen, have the images download in the background

- Ian Tran (Release: 20%, Overall: 30%)

  - Alpha

    - LoginPage SignupPage Implementation

      - Email and password fields connect to Firebase to create and authenticate accounts

      - Implemented logic for handling empty fields

    - Settings Page UI

      - Created base design for settings page

      - Created the buttons and skeleton code for settings page framework

      - Logout button that stops firebase session

      - Implemented Privacy toggle to reflect current value in Firebase

    - FireBase Setup

      - Worked with Daniel to configure firebase for the application

      - Created Firebase database and project

    - Privacy implementation

      - Added functionality to privacy toggle inside settings UI to connect to Firebase

      - Implemented hidden profiles in OtherProfilePage if privacy is enabled

  - Beta

    - Setup Firebase Cloud Storage for storing image files

    - Added constraints to splash screen, location page, signup, login to be centered

    - Added basic comment functionality in Posts page to allow users to post comments, and updated Feed pages to show number of comments respectively

    - Minor Change to Settings to map to Edit Profile Page

    - Altered code in both Feed pages to sort the posts by the most recent

    - Added functionality to link from a user’s post to Profile Page when clicking the icon

- Austin Nguyen (Release: 20%, Overall: 20%)

  - Alpha

    - Discover Page

      - Added prototypes posts data with names and coordinates

      - UISearchBar with search functionality to search posts by name

      - UIMapKit with pinned locations and zoom functionality 

    - Mode View Controller

      - View controller superclass that manages dark and light mode for sub classes

    - Theme manager class

      - Handles user’s preferred settings and provides synchronous alerts  across all view controllers 

  - Beta

    - Implemented search bar to search and retrieve restaurant information

    - Created search results to hold results of restaurant search

    - Refactored discover page

    - Add post page includes required option to search for restaurant and include location identification to post

    - Added locations collections in database to hold restaurant information along with associated posts

    - Added view controller to display restaurant address, location on map, and name

    - Added functionality to redirect user to display restaurant info when checking location of post 

\


**Deviations:**

- We have a small problem with posts right now. If you make a post and then change your name, the name on that post will not reflect what you just changed it to. This is due to how we are storing posts and who posted what. This is a small issue; we just don’t have time to fix it right now. If you don’t change your name, however, the post will show the correct username of the person who posted. 
