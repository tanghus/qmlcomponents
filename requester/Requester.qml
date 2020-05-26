/*
  Copyright (c) 2020 Thomas Tanghus
  All rights reserved.

  You may use this file under the terms of BSD license in the LICENSE
  file distributed with the software.
*/

import QtQuick 2.6

WorkerScript {
    id: requester
    source: Qt.resolvedUrl("./requester.js")
    property string url: ""
    property var order
    property int timeout: 10 // seconds.
    property Timer timer
    property var _func

    // TODO: IDEA: Pass a ListModel the script can optionally populate.
    // function request(args, model) {
    function request(args, cb) {
        //console.log('Requester.request:', JSON.stringify(args))
        //timeout = (args && args.timeout) ? args.timeout : timeout
        _func = cb ? cb : null
        sendMessage({url: url, args: args})
        try {
            timer.start()
        } catch(e) {
            // I can't figure out how to catch this?
            console.log("Requester.request:", e)
        }
    }

    timer: Timer {
        id: timer
        interval: timeout*1000; running: false; repeat: false
        onTriggered: {
            if(_func) {
                // Will this work
                _func({status:"error", message: qsTr("Requester (func) timed out at: %1".arg(url))})
                // Or this
                message({status:"error", message: qsTr("Requester (message) timed out at: %1".arg(url))})
            }
            console.trace()
            _func = null
            throw new Error("Requester: " + qsTr('Requester timed out at: %1'.arg(url)))
        }
    }

    onMessage: {
        timer.stop()
    }

    Component.onCompleted: {
        if(url === "") {
            console.trace()
            throw new Error("Requester: " + qsTr("'url' must be set by subclasses."))
        }
    }
}
