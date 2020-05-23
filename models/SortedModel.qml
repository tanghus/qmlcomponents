/*
 Most of the code about DelegateModel is from:
 https://doc.qt.io/qt-5/qtquick-tutorials-dynamicview-dynamicview4-example.html
    Copyright (C) 2017 The Qt Company Ltd.
    Contact: https://www.qt.io/licensing/

    Changes to a generalized type are copyright (c) 2020 Thomas Tanghus <thomas@tanghus.net>
*/

import QtQuick 2.6
import QtQml.Models 2.3
//import Sailfish.Silica 1.0
//import "."

DelegateModel {
    id: visualModel
    //model: channelModel
    //delegate: channelDelegate

    // NOTE: Maybe change this when searching.
    property var lessThan: [
        //function(left, right) { return left.sort > right.sort },
        //function(left, right) { return left.title < right.title }
    ]

    property int sortOrder: 0

    Component.onCompleted: {
        items.setGroups(0, items.count, 'unsorted')
    }

    function insertPosition(lessThan, item) {
        var lower = 0
        var upper = items.count
        while (lower < upper) {
            var middle = Math.floor(lower + (upper - lower) / 2)
            var result = lessThan(item.model, items.get(middle).model);
            if (result) {
                upper = middle
            } else {
                lower = middle + 1
            }
        }
        return lower
    }

    function sort(lessThan) {
        while (unsortedItems.count > 0) {
            var item = unsortedItems.get(0)
            var index = insertPosition(lessThan, item)
            item.groups = 'items'
            items.move(item.itemsIndex, index)
        }
    }

    items.includeByDefault: false

    groups: DelegateModelGroup {
        id: unsortedItems
        name: 'unsorted'

        includeByDefault: true

        onChanged: {
            if (visualModel.sortOrder === visualModel.lessThan.length) {
                setGroups(0, count, "items")
            } else {
                visualModel.sort(visualModel.lessThan[visualModel.sortOrder])
            }
        }
    }
}
