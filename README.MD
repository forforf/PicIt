# PicIt

 ### One-click picture taking.

## Instructions
1. Open App
2. Point Camera
3. There is no step 3 ... PicIt takes the picture after it's timer is done.

## Configuration

### Timer

Default: 3.0 seconds

### Number of Pics taken
TBD

### Interval between pics
TBD

# About

Modified from the open sourced (MIT Licensed) [SwiftCamera](https://github.com/rorodriguez116/SwiftCamera) app.

# Challenges and Learnings

## General Learnings
* SwiftUI development
  * Using Observables and reactive programming techniques (I was already familiar with reactive programming)
  * Managing view state, and inter-view communication

## Tap on Thumbnail

### To Share

Adding the tap gesture to the thumbnail was easy, took 5 minutes. It took a few hours to figure out how sharing works in iOS (Share sheet).
Spent a couple more hours of research looking for a "SwiftUI"-like way to do sharing, but the only examples I could find were wrapping UIKit using `UIViewControllerRepresentable`.
I was able to use that to trigger sharing by tapping on the thumbnail.

### To Delete

After getting sharing to work, I got tired of having to go into Photo Library to delete all the test photos. So I realized I needed a view to handle different actions when tapping on the thumbnail preview. It took only about a couple hours to figure out how to load a new view (actually it's a modal) for actions on the thumbnail that included share (leveraging the existing sharing controller) and delete. Figuring out how to delete did take a bit of research, and required some retrofitting as I needed to get the "local ID" of the photo and use that as a handle to delete from the photo library. Essentially this equivalent to getting the filename of the saved photo and using that filename later to delete the photo from the libary. I didn't like the fact that I had to introduce code for deleting from the Photo Library, but I didn't like the alternative. The alternative I (only very) briefly considered was, rather than saving the image, keep the image in memory and delete it from memory before saving it. I quickly discarded the idea, because it made the case for saving (i.e. not deleting) the image  overly complex. For example, when would we know that there was no intention of deleting the image and it was safe to save it? Plus what would happen if the app quit before the image was saved, and it felt like there were other edge cases that would crop up as well.

Unfortunately, one consequence of deleting was that returning to the main app screen would then retrigger the timer, and the app would take another picture. I'm still in the process of deciding on the best approach to handle this. I have a very ugly work-around where I basically have a global flag that tells the code whether it should disable the countdown, and I set this flag when the delete button is pushed. I'm looking into alternatives. 


### Learnings

* How to share objects in iOS/Swift apps
* Share sheet requires wrapping UIKit with `UIViewControllerRepresentable`
* Deleting media from Photo (media) Library
* Delete dialog seems to put app to background (not sure why delete behaves this way, but not sharing)

## Timer Publisher

Still work in progress. Started with Timer in view, moved it to a model, but the original model was very basic and monolithic. Essentially it could only do countdowns.
Current model has split out the various timer observal logic into a separate file/struct: `TimerPublishers.swift`. The observables in `TimerPublishers` have been decomposed into basic building blocks:
* `intervalPublisher`: An observable that publishes a unix timestamp on a given interval (thin wrapper around combine's `Timer.Publish`)
* `elapsedPublisherClosure`: A closure that returns an observable that provides the elapsedTime given the start time at periodic intervals (intervals come from `intervalPublisher`)
* `countdownPublisher`: An observable that generates a countdown given a the countdown to start from and a time the countdown started (usually immediate). Uses `elapsedPUblisherClosure`. 
The `Countdown` class is an `ObservableObject`. It uses `countdownPublisher` for countdown events, and emits both a countdown timer and state changes related to the countdown (i.e, whether the timer is in progress, triggering, complete, etc)


## Timer Performance Issues on Return from Background

Although thie initial countdown and picture taking would work as expected, when the app was put in the background and re-opened, the performance was extremely bad, and the countdown updates/picture taking timing was slow and erratic. One theory is that the reference to the model may not have been released or cleaned up adequately and when restoring from background the timer might be wack because of *reasons* (i.e., I'm making guesses). Refactoring the model to support canceling the timer seemed to fix an issue with multiple timers being instatiated, but it seemed that whenever I tried to keep state in the model across scene phases the performance issue would occur. Moving that state out of the model into a global variable fixed the issue, but at the expense of having a global variable. Creating a `@State` variable on the view also led to the same performance issues.

To be more concrete: When deleting an image, the built-in iOS Delete dialog ("Allow PicIt to delete this photo") would send the PicIt app to the background. This meant that after returning from that dialog the countdown would restart, however from a user perspective the App was really never in the background, so the desired behavior would be that countdown state would stay the same. On the other hand, if the user did close the app (which sends it to the background) and later re-opens the app, we do want the countdown to restart. So the app needed a way to track if it was returning to active state from a delete dialog or not, but without updating the view state. Although I'm not that happy with it, the current approach is to set a global flag that indicates whether to enable the countdown to start or not.

As a compromise it has a longish/slightly annoying name: `AvoidStateChange.returningFromSystemDeletePrompt`. This flag is checked upon returning to the active state, and will only start the countdown when it is false. This approach seems to have solved the performance issue.

**Update**: The performance issue returned after a refactor, and this time I was able to identify the root cause. In this case, there was a closure (deleteAction) that held a reference to the camera model (specifically the line of code was `self.model.photo = nil` ). When this code was contained in the closure, the return from background had terrible performance. The fix was to move the code from the closure and handle it as we do the countdown based on the global `AvoidStateChange.returningFromSystemDeletePrompt` flag.
