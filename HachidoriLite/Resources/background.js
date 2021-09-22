function sendMessageToTabs(tabs) {
    console.log("detecting");
  for (let tab of tabs) {
      let result = detectStream(tab);
      console.log(result);
  }
}

browser.browserAction.onClicked.addListener(() => {
  browser.tabs.query({
    currentWindow: true,
    active: true
  }).then(sendMessageToTabs);
});

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
            detectFunimationHistory(tab)
        }
    }
    else {
          getDOM(tab);
    }
}

function generateResult(tab,value) {
    let dom = value[0];
    let result = {};
    if (dom.length > 0) {
        result = {"title" : tab.title, "url" : tab.url, "DOM" : dom, "type" : "detection"};
    }
    else {
        result = {"message" : "invalid page", "type" : "error"};
        showalert(tab,"This is not a valid page to Scrobble.");
    }
    let fresult = JSON.stringify(result);
    console.log(fresult);
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

function promptUpdate(tab,value,result) {
    console.log(value[0]);
    if (value[0]) {
        browser.runtime.sendNativeMessage("application.id", {"type" : "update", "data" : result}, function(response) {
            console.log("Received sendNativeMessage response:");
            console.log(response);
            showalert(tab,"Open the Shukofukurou app to finish the scrobble process.")
        });
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


