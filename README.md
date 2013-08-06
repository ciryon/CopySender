## Introduction ##

CopySender is a solution to capture anything you copy (with CMD-C or Copy from the Edit menu) on your Mac and send it securely (basic auth over HTTPS preferably) to your own server. The purpose is to quickly transfer text to your other devices. The text is visible in a very simple auto-refreshing web page.

Here's a video explaining what it does:

<iframe width="560" height="315" src="//www.youtube.com/embed/udLx8XgnVYk" frameborder="0" allowfullscreen></iframe>

## Components ##

* Mac OS X app that you keep running as long as you want CopySender enabled
* Sinatra webapp that responds to POSTs from the app and displays a web page

## Disclaimer ##

This is a very simple solution that I created for myself. The copied text will, by default, be present in a text file in /tmp that potentially can be read by other users on your system. I don't want to bother with anything like a database to keep this simple data. The password used is stored unencrypted in standard user defaults (an easy to find plist-file) for the Mac app and in a configuration file for the Sinatra webapp. Don't use a sensitive password.

## Installation ##

`git clone` this repo and check out the contents:

### Mac app ###

* Make sure you have CocoaPods installed with `gem install cocoapods`
* Type `pod install` to install the AFNetworking dependency
* Open CopySender.xcworkspace and build the app in XCode
* Install it anywhere you want and perhaps launch it at login


### Sinatra webapp ###

On your localhost:

* Go to the cloned repo and subfolder webapp
* Make sure you have bundler installed: `gem install bundler`
* Type `bundle install` to install the dependencies
* Type `ruby server.rb` to start via WEBrick (read below about configuration first though)

You can also install this app behind Apache or Nginx (this is recommended) and then you need to edit your virtual hosts config file. Instructions for how to do that is beyond the scope of this document.

## Configuration ##

## Mac app ##

Just enter hostname (name or IP prefixed by https:// or http://), port and password of your choice. Then click Start.

## Sinatra webapp ##

Edit the settings.yml file and change password to what you want. Notice that the file isn't stored securely so don't use an existing password. You can also change how often the web UI will auto-refresh. 


# Is this useful or cool? #

Let me know by staring the repo, forking it, contributing to it or just send me a message. :)


# Licence

Oh, glad you asked. CopySender is free to use under the [Do What the Fuck You Want To Public Licence](http://www.wtfpl.net) (WTFPL):

Copyright © 2013 Christian Hedin <ciryon@mac.com>
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the COPYING file for more details.