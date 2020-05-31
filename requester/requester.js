/*
  Copyright (c) 2020 Thomas Tanghus
  All rights reserved.

  You may use this file under the terms of BSD license in the LICENSE
  file distributed with the software.
*/

//import "utils.js" as Utils
//Qt.include("dates.js") <- works
WorkerScript.onMessage = function(message) {
    //console.log('Requester.onMessage', JSON.stringify(message))
    var url = message.url.supplant(message.args)
    //console.log('Requester.onMessage', JSON.stringify(message))
    //console.log('requester.js.onMessage. url:', url)

    var xhr = new XMLHttpRequest();

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if(xhr.status >= 200 && xhr.status < 300) {
                //console.log('requester: status/size:', xhr.status, xhr.statusText, xhr.responseText.length)
                var result = JSON.parse(xhr.responseText);

                WorkerScript.sendMessage({
                        'status': 'success',
                        result: result,
                        request: message,
                        args: message.args
                });

            } else {
                // NOTE: Can we be sure responseText can be parsed as JSON?
                console.error('requester.js', xhr.statusText, JSON.parse(xhr.responseText).error);
                WorkerScript.sendMessage({
                        status: 'error',
                        error: xhr.statusText,
                        message: JSON.parse(xhr.responseText).error,
                        request: message
                    }
                );
            }
        }
    }

    xhr.onTimeout = function() {
        WorkerScript.sendMessage({error: 'Request timed out'});
    }

    xhr.open('GET', url, true);
    xhr.timeout = 3000;
    xhr.send();
}


String.prototype.supplant = function (o) {
    try {
        return this.replace(/{([^{}]*)}/g,
            function (a, b) {
                var r = o[b];
                return typeof r === 'string' || typeof r === 'number' ? r : a;
            }
        );
    } catch(e) {

    }
};


