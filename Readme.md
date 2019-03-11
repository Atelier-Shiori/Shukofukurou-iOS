# Shukofukurou for iOS

![screenshot](https://malupdaterosx.moe/wp-content/uploads/2019/02/iPhone-XSiPad-Pro-13-Landscape-Silver-1024x733.png)

Shukofukurou for iOS is the iOS port of [Shukofukurou](https://github.com/Atelier-Shiori/Shukofukurou), which is a lightweight multiservice Anime and Manga library management and discovery app that works with [Kitsu](https://kitsu.io/) and [AniList](https://anilist.co/). MyAnimeList and Anime-Planet support will be added in the future when the APIs become available.

Requires the latest SDK (iOS 12), Xcode 10 or later. This app will run on iOS 11.4 or later.

## App Store Release
Since an Apple Developer Program is required to distribute apps for iOS, Shukofukurou for iOS will cost $2.99 to download, which will have no restrictions and will recieve lifetime updates. The proceeds will go back into supporting the development of our applications. We have to charge for the iOS version since the Apple Developers Program costs $99 a year and we put a lot of work in developing this App. Charging for open source software, believe it or not is [encouraged by the FSF](http://www.gnu.org/philosophy/selling.html).

However, the source code will remain free for anyone who want it., However, you will need an Apple Developer Program membership to use the application indefinately since Apple limits device provisioning for 7 days on a free account. After 7 days, the app will not run, requiring you to compile and reinstall.

No support will be given to self-built copies. You need to specify the OAuth Client and Secret before you can compile your own version.

If you want to help support us to reach the goal of $10 a month, which will allow us to distribute the app for free while covering the costs of distribution, [become a patron](https://www.patreon.com/join/malupdaterosx) today.

## Compiling Instructions
**Note: Self-compiling is meant for developers and advanced users only. Apple limits provisioning profile that allows you to run your apps on your iOS device for 7 days without a paid Apple Developer membership. If you want to use the app for more than 7 days without having to reinstall it, consider downloading it from the App Store. You can support dvelopment for our App and you don't have to buy a $99 a year Apple Developer Program membership, unless you already have one.**

1. Download or clone this repo. Note that you need to retrieve the submodules or it won't compile.
```git clone --recurse-submodules -j8 https://github.com/Atelier-Shiori/Shukofukurou-iOS.git```
2. Go into the repo folder, open Shukofukurou-IOS > Backend > Constants in finder. Copy the "ClientConstants-sample.m" file and rename it to "ClientConstants.m".
3. Specify the API keys and secrets for Kitsu and Anilist. Kitsu can be found [here](https://kitsu.docs.apiary.io/#) and AniList can be found [here](https://anilist.co/settings/developer/client/). The redirect URL should be set to "hiyokoauth://anilistauth/" for anilist.
4. Open the project in Xcode. To install the app, choose the "Shukofukurou-IOS-OSS" as the target, and  select your device on the device popup menu on the XCode toolbar . **Note: If you are not using a paid Apple Developer Membership, the app will ony run for 7 days before you need to reinstall it.**

## macOS Release?
There is no plans for a macOS release since there is a macOS version, but anyone is free to port it once Apple opens iOS App porting to the Mac in 2019.

## Dependencies
All the frameworks are included. Just build! Here are the frameworks that are used in this app so far:
* ActionSheetPicker.framework
* AFNetworking.framework
* Hakuchou_iOS.framework
* LGSideMenuController.framework
* MGSwipeTableCell.framework
* SAMKeychain.framework
* SDWebImage.framework

See Third Party in the Settings view for third-party licenses terms.

Icons provided by [Icons8](https://icons8.com/)

## License
Unless stated, Source code is licensed under New BSD License
