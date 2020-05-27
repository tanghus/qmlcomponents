import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: button
    property bool on: false
    property alias text: buttonText.text
    property alias verticalAlignment: buttonText.verticalAlignment
    property alias truncationMode: buttonText.truncationMode
    property alias pixelSize: buttonText.font.pixelSize
    property alias bold: buttonText.font.bold
    property alias color: buttonText.color

    contentItem.width: parent.width < parent.height
                       ? Math.round(parent.width*0.6)
                       : Math.round(parent.height*0.6)
    //width: buttonText.width + Theme.paddingLarge
    contentItem.height: contentItem.width
    contentItem.color: on ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                          : Theme.rgba(Theme.highlightBackgroundColor, 0.4)
    contentItem.radius: width*0.5
    contentItem.opacity: on ? 1.0 : 0.4
    contentItem.anchors.centerIn: button
    Label {
        id: buttonText
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeLarge
        color: on ? Theme.highlightColor : Theme.primaryColor
    }
}
