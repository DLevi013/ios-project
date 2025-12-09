# **Foocation**

A social iOS application for sharing food and restaurant experiences. Users can post photos of meals, explore restaurants, and see food from people they follow. Similar to Instagram/BeReal, but focused on food discovery.

## **Team & Project Info**
**Group Number:** 7  
**Team Members:** Isaac Thomas, Ian Tran, Austin Nguyen, Daniel Levi  
**Project Name:** Foocation  

## **Frameworks Used**
FirebaseAuth, FirebaseCode, FirebaseDatabase, FirebaseFirestore, Firebase Storage, SDWebImage, SDWebImageMapKit  

## **Dependencies**
- Xcode 16  
- iOS 26 deployment target  

## **How to Run**
Open the project in Xcode and run using:  

**Device:** iPhone 17 Pro Max  

### Test Accounts (already populated)
| Email | Password |
|---|---|
| daniel@daniel.com | 123456 |
| isaac@isaac.com | 12341234 |

## **Feature Overview and Release Tracking**

| Feature | Description | Planned Release | Actual Release | Deviations (original text) | Who / % Worked |
|---|---|---|---|---|---|
| Registration / Login Screen | What the user sees when they first open the app. What they see when they want to login/signup. | Alpha | Alpha | None | Daniel 40%, Ian 40%, Isaac 20% |
| Home Screen | Loading/opening the app page | Alpha | Alpha | None | Daniel 40%, Ian 40%, Isaac 20% |
| Settings Screen | The screen where all the settings are located | Alpha | Alpha | *The UI and VC for the settings screen was present for the alpha release, but not all features we wanted Users to be able to change were implemented for the Alpha release. All the settings we wanted users to be able to change were implemented for the Final Release.* | Ian 50%, Isaac 50% |
| Create Post Functionality | The UI of the Create Post Page along with all the functionality connected with it. | Alpha | Alpha | *UI and functionality was implemented for Alpha release, but was not connected to the database until the Beta Release.* | Daniel 40%, Isaac 60% |
| Profile Page | The Profile page and posts/map/friends list implementation. | Alpha | Alpha | *None, but edit profile was not fully implemented until Beta Release, slight UI changes made in Beta and Final Release.* | Daniel 90%, Isaac 10% |
| Feed Page | A populated feed that is scrollable. | Beta | Alpha | *Implemented for the Alpha release, but not connected to the database until Beta Release.* | Daniel 20%, Isaac 80% |
| Likes / Comments | Likes and comments buttons are clickable, and clicking on comments shows all the comments. Users can add their own comments. | Beta | Beta | None | Daniel 30%, Isaac 70% |
| Friends / Follower System | Users each have their own list of users that they are friends with. | Beta | Alpha | *Was scheduled for the Beta Release, but we implemented this in the Alpha release. Added the ability to remove friend in Beta Release.* | Daniel 50%, Isaac 50% |
| Display Restaurant / Location | Button on post that will segue into another view to see restaurant location and associated posts. | Beta | Final | None | Austin 100% |
| Time-based Notifications | Users get notifications at certain times to post and also when they hit certain milestones. | Final | Final | None | Ian 100% |
| Filters for Location | Search restaurants by filters | Final | Final | *Unable to sort by cuisine or distance, instead search by user location. (Map is focused on users location when they open the app, so the map “filters” based on where the user is located)* | Daniel 20%, Austin 80% |

## **Extra Notes**
Search filters cannot sort by cuisine or distance; instead, the map focuses on the user’s current location.  

## **Summary**
Foocation provides a social and location-based way to document food experiences, discover restaurants, and see what friends are eating around them. The goal is to create a personal, authentic alternative to Yelp/Google Reviews.
