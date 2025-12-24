import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Core

PanelWindow {
    id: root

    property bool isOpen: false
    required property var globalState
    required property Colors colors

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "matte-power-menu"
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
        if (visible) {
            eventHandler.forceActiveFocus()
        }
    }

    FocusScope {
        id: eventHandler
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: globalState.powerMenuOpen = false
        Keys.onLeftPressed: {
            currentIndex = (currentIndex - 1 + buttonsModel.count) % buttonsModel.count
        }
        Keys.onRightPressed: {
            currentIndex = (currentIndex + 1) % buttonsModel.count
        }
        Keys.onReturnPressed: {
            runCommand(buttonsModel.get(currentIndex).command)
        }
    }

    property int currentIndex: 2

    ListModel {
        id: buttonsModel
        ListElement { name: "Lock"; icon: "󰌾"; command: "loginctl lock-session" }
        ListElement { name: "Suspend"; icon: "󰒲"; command: "systemctl suspend" }
        ListElement { name: "Shutdown"; icon: "󰐥"; command: "systemctl poweroff" }
        ListElement { name: "Reboot"; icon: "󰜉"; command: "systemctl reboot" }
        ListElement { name: "Logout"; icon: "󰍃"; command: "loginctl terminate-user $USER" }
    }
    
    function runCommand(cmd) {
        // Resolve environment variables if needed
        if (cmd.includes("$USER")) {
            cmd = cmd.replace("$USER", Quickshell.env("USER"))
        }

        console.log("PowerMenu: Executing command:", cmd)
        Quickshell.execDetached(["sh", "-c", cmd])
        globalState.powerMenuOpen = false
    }

    // Dimmer
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: isOpen ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: globalState.powerMenuOpen = false
        }
    }

    // Centered Row
    Row {
        anchors.centerIn: parent
        spacing: 30
        
        // Smoothly animate sibling movement
        move: Transition {
            NumberAnimation { properties: "x"; duration: 250; easing.type: Easing.OutExpo }
        }
        
        Repeater {
            model: buttonsModel
            
            delegate: Rectangle {
                id: delegateRoot
                required property string name
                required property string icon
                required property string command
                required property int index
                
                property bool isSelected: root.currentIndex === index
                property bool isHovered: mouseArea.containsMouse
                
                width: isSelected || isHovered ? 140 : 100
                height: 140
                radius: 24
                
                // Ensure the selected item is visually on top during any overlap/transition
                z: isSelected || isHovered ? 10 : 1
                
                color: (isSelected || isHovered) ? root.colors.accent : root.colors.surface
                border.width: 1
                border.color: (isSelected || isHovered) ? root.colors.accent : root.colors.border
                
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }
                
                // Content
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Text {
                        text: delegateRoot.icon
                        font.pixelSize: 42
                        font.family: "Symbols Nerd Font"
                        color: (delegateRoot.isSelected || delegateRoot.isHovered) ? root.colors.bg : root.colors.text
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Text {
                        text: delegateRoot.name
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: (delegateRoot.isSelected || delegateRoot.isHovered) ? root.colors.bg : root.colors.text
                        opacity: (delegateRoot.isSelected || delegateRoot.isHovered) ? 1 : 0
                        visible: opacity > 0
                        Layout.alignment: Qt.AlignHCenter
                        
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.currentIndex = index
                    onClicked: root.runCommand(delegateRoot.command)
                }
            }
        }
    }
}
