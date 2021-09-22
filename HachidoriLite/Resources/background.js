//
//  background.js
//  Hachidori Lite Extension
//
//  Created by 千代田桃 on 9/21/21.
//  Copyright © 2021 MAL Updater OS X Group. All rights reserved.

function sendMessageToTabs(tabs) {
    console.log("detecting");
  for (let tab of tabs) {
      browser.runtime.sendNativeMessage("application.id", {"type" : "checklogin"}, function(response) {
          console.log("Received sendNativeMessage response:");
          console.log(response);
          if (response["result"]) {
              browser.runtime.sendNativeMessage("application.id", {"type" : "promptexisting"}, function(response) {
                  console.log("Received sendNativeMessage response:");
                  console.log(response);
                  if (response["result"]) {
                      let executing = browser.tabs.executeScript(tab.id, { code: 'window.confirm("There is an scrobble that is pending. If you continue, it will be overwritten. Is this okay?");'});
                      executing.then((value) => {
                          return promptUpdateOverwrite(tab,value);
                      });
                  }
                  else {
                      let result = detectStream(tab);
                  }
              });
          }
          else {
              showalert(tab,"You cannot scrobble a title unless you are logged in. Launch Shukofukurou, log into an account and try again.")
          }
      });
  }
}

browser.browserAction.onClicked.addListener(() => {
    performScrobble();
});

function performScrobble() {
    browser.tabs.query({
      currentWindow: true,
      active: true
    }).then(sendMessageToTabs);
}

function detectStream(tab) {
    var url = tab.url;
    if (url.includes("crunchyroll")) {
        if (url.includes("history")) {
            detectCrunchyrollHistory(tab);
        }
        else {
            detectCrunchyroll(tab);
        }
    }
    else if (url.includes("funimation")) {
        if (url.includes("account")) {
            detectFunimationHistory(tab);
        }
        else if (url.includes("/v/")) {
            detectFunimationNewPlayer(tab);
        }
        else {
            getDOM(tab);
        }
    }
    else {
          getDOM(tab);
    }
}

function generateResult(tab,value) {
    let dom = value[0];
    let result = {};
    if (dom) {
        if (dom.length > 0) {
            result = {"title" : tab.title, "url" : tab.url, "DOM" : dom, "type" : "detection"};
        }
        else {
            result = {"message" : "invalid page", "type" : "error"};
            showalert(tab,"This is not a valid page to Scrobble.");
        }
        browser.runtime.sendNativeMessage("application.id", result , function(response) {
            console.log("Received sendNativeMessage response:");
            console.log(response);
            let result = response["results"][0];
            let executing = browser.tabs.executeScript(tab.id, { code: 'window.confirm("Update ' + result["title"] + ' Episode ' + result["episode"] + '?");'});
            executing.then((value) => {
                return promptUpdate(tab,value,result);
            });
        });
    }
    else {
        result = {"message" : "invalid page", "type" : "error"};
        showalert(tab,"This is not a valid page to Scrobble.");
    }
}

function promptUpdate(tab,value,result) {
    if (value[0]) {
        browser.runtime.sendNativeMessage("application.id", {"type" : "update", "data" : result}, function(response) {
            console.log("Received sendNativeMessage response:");
            console.log(response);
            showalert(tab,"Open the Shukofukurou app to finish the scrobble process.")
        });
    }
}

function promptUpdateOverwrite(tab,value) {
    if (value[0]) {
        let result = detectStream(tab);
        console.log(result);
    }
}

function showalert(tab,message) {
    let executing = browser.tabs.executeScript(tab.id, { code: 'alert("' + message + '");'});
    executing.then((value) => {
        return true;
    });
}

function getDOM(tab) {
    let executing = browser.tabs.executeScript(tab.id, { code: 'document.documentElement.innerHTML'});
    executing.then((value) => {
        return generateResult(tab,value);
    });
}

function detectCrunchyroll(tab) {
    let executing = browser.tabs.executeScript(tab.id, { code: "document.querySelector('.erc-current-media-info').innerHTML"});
    executing.then((value) => {
        return generateResult(tab,value);
    });
}
function detectCrunchyrollHistory(tab) {
    letexecuting =  browser.tabs.executeScript(tab.id, { code: "document.querySelector('.history-collection').innerHTML"});
    executing.then((value) => {
        return generateResult(tab,value);
    });
}

function detectFunimationHistory(tab) {
    let executing = browser.tabs.executeScript(tab.id, { code: "document.querySelector('.history-item').innerHTML"});
    executing.then((value) => {
        return generateResult(tab,value);
    });
}

function detectFunimationNewPlayer(tab) {
    let executing = browser.tabs.executeScript(tab.id, { code: "document.querySelector('.meta-overlay__data-block--title').innerHTML + ' | ' + document.querySelector('.meta-overlay__data-block--episode-and-season').innerHTML;"});
    executing.then((value) => {
        return generateResult(tab,value);
    });
}
