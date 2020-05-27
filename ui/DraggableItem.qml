/*
 * listviewdragitem
 *
 * An example of reordering items in a ListView via drag'n'drop.
 *
 * Author: Aurélien Gâteau
 * License: BSD
 *
 * Adapted for Sailfish OS by Thomas Tanghus <thomas@tanghus.net>
 */
import QtQuick 2.6
import Sailfish.Silica 1.0

ListItem {
    id: root

    default property Item contentItem

    // This item will become the parent of the dragged item during the drag operation
    property Item draggedItemParent

    signal moveItemRequested(int from, int to)

    // Size of the area at the top and bottom of the list where drag-scrolling happens
    property int scrollEdgeSize: 10

    // Internal: set to -1 when drag-scrolling up and 1 when drag-scrolling down
    property int _scrollingDirection: 0

    // Internal: shortcut to access the attached ListView from everywhere. Shorter than root.ListView.view
    property ListView _listView: ListView.view

    property alias enabled: dragArea.enabled

    //width: contentItem.width
    height: topPlaceholder.height + wrapperParent.height + bottomPlaceholder.height
    contentHeight: height

    // Make contentItem a child of contentItemWrapper
    onContentItemChanged: {
        //console.log("DraggableItem.onContentItemChanged")
        contentItem.parent = contentItemWrapper;
    }

    Rectangle {
        id: topPlaceholder
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: 0
        color: Theme.highlightDimmerColor
    }

    Item {
        id: wrapperParent
        anchors {
            left: parent.left
            right: parent.right
            top: topPlaceholder.bottom
        }
        height: contentItem.height

        SilicaItem {
            id: contentItemWrapper
            anchors.fill: parent
            Drag.active: dragArea.drag.active
            Drag.hotSpot {
                x: contentItem.width / 2
                y: contentItem.height / 2
            }
            Drag.onDragStarted: {
                console.log("DraggableItem.contentItemWrapper.onDragStarted")
            }
            Drag.onDragFinished: {
                console.log("DraggableItem.contentItemWrapper.onDragFinished")
            }
            MouseArea {
                id: dragArea
                anchors.fill: parent
                //pressAndHoldInterval: 500 // Not available in Qt 5.6
                // Prevent accidental drags
                drag.target: dragActive ? parent : undefined // parent
                drag.axis: ListView.orientation === ListView.Horizontal ? Drag.XAxis : Drag.YAxis
                // Disable smoothed so that the Item pixel from where we started the drag remains under the mouse cursor
                //drag.smoothed: false
                property bool dragActive: false
                onCanceled: {
                    console.log("DraggableItem.dragArea.onCanceled")
                    root.highlighted = false
                    dragActive = false
                }
                onPressAndHold: {
                    console.log("DraggableItem.dragArea.onPressAndHold")
                    root.highlighted = true
                    // Enable drags
                    dragActive = true
                }
                onReleased: {
                    console.log("DraggableItem.dragArea.onReleased")
                    root.highlighted = false
                    if (drag.active) {
                        emitMoveItemRequested();
                    }
                    dragActive = false
                }
                onEntered: console.log("dragArea.onEntered")
            }
        }
    }

    Rectangle {
        id: bottomPlaceholder
        anchors {
            left: parent.left
            right: parent.right
            top: wrapperParent.bottom
        }
        height: 0
        color: Theme.highlightDimmerColor
    }

    SmoothedAnimation {
        id: upAnimation
        target: _listView
        property: "contentY"
        to: 0
        running: _scrollingDirection == -1
    }

    SmoothedAnimation {
        id: downAnimation
        target: _listView
        property: "contentY"
        to: _listView.contentHeight - _listView.height
        running: _scrollingDirection == 1
    }

    Loader {
        id: topDropAreaLoader
        active: model.index === 0
        anchors {
            left: parent.left
            right: parent.right
            bottom: wrapperParent.verticalCenter
        }
        height: contentItem.height
        sourceComponent: Component {
            DropArea {
                property int dropIndex: 0
            }
        }
    }

    DropArea {
        id: bottomDropArea
        anchors {
            left: parent.left
            right: parent.right
            top: wrapperParent.verticalCenter
        }
        enabled: !dragArea.drag.active
        property bool isLast: model.index === _listView.count - 1
        height: isLast ? _listView.contentHeight - y : contentItem.height

        property int dropIndex: model.index + 1
    }

    states: [
        State {
            when: dragArea.drag.active
            name: "dragging"

            ParentChange {
                target: contentItemWrapper
                parent: draggedItemParent
            }
            PropertyChanges {
                target: contentItemWrapper
                opacity: 0.9
                anchors.fill: undefined
                width: contentItem.width
                height: contentItem.height
            }
            PropertyChanges {
                target: wrapperParent
                height: 0
            }
            PropertyChanges {
                target: root
                _scrollingDirection: {
                    var yCoord = _listView.mapFromItem(dragArea, 0, dragArea.mouseY).y
                    if (yCoord < scrollEdgeSize) {
                        -1
                    } else if (yCoord > _listView.height - scrollEdgeSize) {
                        1
                    } else {
                        0
                    }
                }
            }
        },
        State {
            when: bottomDropArea.containsDrag
            name: "droppingBelow"
            PropertyChanges {
                target: bottomPlaceholder
                height: dragArea.enabled ? contentItem.height : 0
            }
            PropertyChanges {
                target: bottomDropArea
                height: dragArea.enabled ? contentItem.height * 2 : 0
                //height: contentItem.height * 2
            }
        },
        State {
            when: topDropAreaLoader.item !== null ? topDropAreaLoader.item.containsDrag : false
            name: "droppingAbove"
            PropertyChanges {
                target: topPlaceholder
                //height: contentItem.height
                height: dragArea.enabled ? contentItem.height : 0
            }
            PropertyChanges {
                target: topDropAreaLoader
                height: dragArea.enabled ? contentItem.height * 2 : 0
                //height: contentItem.height * 2
            }
        }
    ]

    function emitMoveItemRequested() {
        var dropArea = contentItemWrapper.Drag.target
        if (!dropArea) {
            return
        }
        var dropIndex = dropArea.dropIndex
        console.log("DraggableItem.emitMoveItemRequested. dropIndex:", dropIndex, "- model.index:", model.index)

        // If the target item is below us, then decrement dropIndex because the target item is going to move up when
        // our item leaves its place
        if (model.index < dropIndex) {
            dropIndex--
        }
        if (model.index === dropIndex) {
            return
        }
        root.moveItemRequested(model.index, dropIndex)

        // Scroll the ListView to ensure the dropped item is visible. This is required when dropping an item after the
        // last item of the view. Delay the scroll using a Timer because we have to wait until the view has moved the
        // item before we can scroll to it.
        makeDroppedItemVisibleTimer.start()
    }

    Timer {
        id: makeDroppedItemVisibleTimer
        interval: 0
        onTriggered: {
            console.log("DraggableItem.makeDroppedItemVisibleTimer", model.index)
            _listView.positionViewAtIndex(model.index, ListView.Center)
        }
    }
}
