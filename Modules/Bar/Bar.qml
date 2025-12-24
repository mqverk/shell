import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Core
import "../../Services" // Import MprisService

Rectangle {
    id: barRoot

    // Required properties from the main configuration
    required property Colors colors
    required property string fontFamily
    required property int fontSize
    required property string kernelVersion
    required property int cpuUsage
    required property int memUsage
    required property int diskUsage
    required property int volumeLevel
    required property string activeWindow
    required property string currentLayout
    required property string time

    anchors.fill: parent
    color: colors.bg
    radius: 12
    border.color: colors.muted
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // 1. Logo
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: height / 2
            color: "transparent"

            Image {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: "../../Assets/arch.svg"
                fillMode: Image.PreserveAspectFit
                opacity: 0.9
            }
        }

        VerticalDivider {}

        // 2. Info Panel Toggle
        Rectangle {
            Layout.preferredHeight: 26
            Layout.preferredWidth: 26
            radius: height / 2
            color: "transparent"
            border.color: colors.muted
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰃰"
                font.pixelSize: 16
                font.family: "Symbols Nerd Font"
                color: colors.blue
            }

            Process {
                id: infoPanelIpcProcess
                command: ["quickshell", "ipc", "-c", "mannu", "call", "infopanel", "toggle"]
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: parent.color = Qt.rgba(colors.blue.r, colors.blue.g, colors.blue.b, 0.2)
                onExited: parent.color = "transparent"
                onClicked: infoPanelIpcProcess.running = true
            }
        }

        // 3. Workspace Switcher
        Rectangle {
            id: wsContainer
            Layout.preferredWidth: 150
            Layout.preferredHeight: 26
            color: Qt.rgba(0, 0, 0, 0.2)
            radius: height / 2
            clip: true

            MouseArea {
                anchors.fill: parent
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y > 0)
                        Hyprland.dispatch("workspace -1");
                    else
                        Hyprland.dispatch("workspace +1");
                }
            }

            ListView {
                id: wsList
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 4
                interactive: false
                currentIndex: (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id - 1 : 0)
                model: 999

                delegate: Item {
                    property int wsIndex: index + 1
                    property var workspace: Hyprland.workspaces.values.find((ws) => ws.id === wsIndex) ?? null
                    property bool isActive: wsList.currentIndex === index
                    property bool hasWindows: workspace !== null

                    height: wsList.height
                    width: indicator.width

                    Rectangle {
                        id: indicator
                        anchors.centerIn: parent
                        height: 16
                        width: parent.isActive ? 32 : 16
                        radius: height / 2
                        color: (parent.isActive || parent.hasWindows) ? colors.accent : "transparent"
                        border.color: (!parent.isActive && !parent.hasWindows) ? colors.muted : "transparent"
                        border.width: (!parent.isActive && !parent.hasWindows) ? 2 : 0

                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Hyprland.dispatch("workspace " + parent.wsIndex)
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        VerticalDivider {}

        // 4. Matugen-Themed Media Toggle Button (Connected to MprisService)
        Rectangle {
            id: mediaToggleButton
            Layout.preferredHeight: 26
            Layout.preferredWidth: Math.min(mediaRow.implicitWidth + 24, 250) // Cap max width
            radius: height / 2
            
            // Using Matugen colors: accent as primary, accentActive for hover
            color: mediaMouse.containsMouse ? colors.accentActive : colors.accent
            border.color: Qt.rgba(colors.accent.r, colors.accent.g, colors.accent.b, 0.4)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 100 } }
            scale: mediaMouse.pressed ? 0.94 : 1.0

            RowLayout {
                id: mediaRow
                anchors.centerIn: parent
                spacing: 8
                width: parent.width - 20

                Text {
                    // Toggle icon based on service state
                    text: MprisService.isPlaying ? "󰏤" : "󰐊" 
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 14
                    color: colors.bg
                    font.bold: true
                }

                Text {
                    // Bind title from service
                    text: MprisService.title !== "" ? MprisService.title : "No Media"
                    font.family: fontFamily
                    font.pixelSize: fontSize - 3
                    font.bold: true
                    color: colors.bg
                    opacity: 0.95
                    
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: mediaMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    MprisService.playPause()
                }
            }
        }

        VerticalDivider {}

        // Keyboard Layout
        Text {
            text: currentLayout
            color: colors.fg
            font.pixelSize: fontSize - 2
            font.family: fontFamily
            font.bold: true
            opacity: 0.7
        }

        Item { Layout.fillWidth: true }

        // Active Window Title
        InfoPill {
            visible: activeWindow !== ""
            Layout.maximumWidth: 400
            border.width: 0
            color: Qt.rgba(0, 0, 0, 0.2)

            Text {
                text: activeWindow
                color: colors.fg
                font.pixelSize: fontSize - 1
                font.family: fontFamily
                font.bold: true
                elide: Text.ElideMiddle
                Layout.maximumWidth: 360
            }
        }

        Item { Layout.fillWidth: true }

        // System Stats
        InfoPill {
            Row {
                spacing: 6
                Text { text: "CPU"; color: colors.red; font.bold: true; font.pixelSize: fontSize - 2; anchors.baseline: tCpu.baseline }
                Text { id: tCpu; text: cpuUsage + "%"; color: colors.fg; font.pixelSize: fontSize - 1; font.family: fontFamily }
            }
            VerticalDivider { Layout.preferredHeight: 10 }
            Row {
                spacing: 6
                Text { text: "RAM"; color: colors.blue; font.bold: true; font.pixelSize: fontSize - 2; anchors.baseline: tRam.baseline }
                Text { id: tRam; text: memUsage + "%"; color: colors.fg; font.pixelSize: fontSize - 1; font.family: fontFamily }
            }
        }

        // Volume
        InfoPill {
            Row {
                spacing: 6
                Text { text: "VOL"; color: colors.yellow; font.bold: true; font.pixelSize: fontSize - 2; anchors.baseline: tVol.baseline }
                Text { id: tVol; text: volumeLevel + "%"; color: colors.fg; font.pixelSize: fontSize - 1; font.family: fontFamily; font.bold: true }
            }
        }

        // Wallpaper Panel Toggle
        Rectangle {
            Layout.preferredHeight: 26
            Layout.preferredWidth: 26
            radius: height / 2
            color: "transparent"
            border.color: colors.muted
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰸉"
                font.pixelSize: 16
                font.family: "Symbols Nerd Font"
                color: colors.fg
            }

            Process {
                id: wallpaperIpcProcess
                command: ["quickshell", "ipc", "-c", "mannu", "call", "wallpaperpanel", "toggle"]
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: parent.color = Qt.rgba(colors.accent.r, colors.accent.g, colors.accent.b, 0.2)
                onExited: parent.color = "transparent"
                onClicked: wallpaperIpcProcess.running = true
            }
        }

        // Clock
        Rectangle {
            Layout.preferredHeight: 26
            Layout.preferredWidth: clockText.implicitWidth + 24
            radius: height / 2
            color: colors.accent

            Text {
                id: clockText
                anchors.centerIn: parent
                text: time
                color: colors.bg
                font.pixelSize: fontSize - 1
                font.family: fontFamily
                font.bold: true
            }
        }

        // Power Menu
        Rectangle {
            Layout.preferredHeight: 26
            Layout.preferredWidth: 26
            radius: height / 2
            color: "transparent"
            border.color: colors.muted
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "⏻"
                font.pixelSize: 16
                font.family: "Symbols Nerd Font"
                color: colors.red
            }

            Process {
                id: powerMenuIpcProcess
                command: ["quickshell", "ipc", "-c", "mannu", "call", "powermenu", "toggle"]
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: parent.color = Qt.rgba(colors.red.r, colors.red.g, colors.red.b, 0.2)
                onExited: parent.color = "transparent"
                onClicked: powerMenuIpcProcess.running = true
            }
        }
    }

    // Custom Components
    component VerticalDivider: Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 14
        Layout.alignment: Qt.AlignVCenter
        color: colors.muted
        opacity: 0.5
    }

    component InfoPill: Rectangle {
        default property alias content: innerLayout.data
        Layout.preferredHeight: 26
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: innerLayout.implicitWidth + 20
        radius: height / 2
        color: "transparent"
        border.color: colors.muted
        border.width: 1

        RowLayout {
            id: innerLayout
            anchors.centerIn: parent
            spacing: 8
        }
    }
}