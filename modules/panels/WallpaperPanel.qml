import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../core"
import "../../services"

PanelWindow {
    id: root
    
    required property var globalState
    
    anchors {
        top: true
        left: true
        right: true
    }
    height: 600
    visible: globalState.wallpaperPanelOpen
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "wallpaper-panel"
    WlrLayershell.exclusiveZone: -1
    
    color: "transparent"
    
    property string wallpaperPath: WallpaperService.defaultDirectory
    property int currentScreenIndex: 0
    property string filterText: ""

    Colors { id: theme }
    
    // Local state for filtered wallpapers
    property var wallpapersList: []
    property var filteredWallpapers: []
    property string currentWallpaper: ""
    
    // Update wallpapers list when service emits signal
    Connections {
        target: WallpaperService
        
        function onWallpaperChanged(screenName, path) {
            if (Quickshell.screens[currentScreenIndex] && 
                screenName === Quickshell.screens[currentScreenIndex].name) {
                updateWallpaperData();
            }
        }
        
        function onWallpaperListChanged(screenName, count) {
            if (Quickshell.screens[currentScreenIndex] && 
                screenName === Quickshell.screens[currentScreenIndex].name) {
                updateWallpaperData();
            }
        }
    }
    
    function updateWallpaperData() {
        if (Quickshell.screens[currentScreenIndex]) {
            var screenName = Quickshell.screens[currentScreenIndex].name;
            wallpapersList = WallpaperService.getWallpapersList(screenName);
            currentWallpaper = WallpaperService.getWallpaper(screenName);
            updateFiltered();
        }
    }
    
    function updateFiltered() {
        if (!filterText || filterText.trim().length === 0) {
            filteredWallpapers = wallpapersList;
            return;
        }
        
        var searchText = filterText.toLowerCase();
        var filtered = [];
        for (var i = 0; i < wallpapersList.length; i++) {
            var filename = wallpapersList[i].split('/').pop().toLowerCase();
            if (filename.indexOf(searchText) >= 0) {
                filtered.push(wallpapersList[i]);
            }
        }
        filteredWallpapers = filtered;
    }
    
    Connections {
        target: globalState
        function onWallpaperPanelOpenChanged() {
            if (globalState.wallpaperPanelOpen) {
                updateWallpaperData();
                searchInput.text = "";
                filterText = "";
            }
        }
    }
    
    // Click outside to close - background layer
    MouseArea {
        anchors.fill: parent
        onClicked: {
            globalState.wallpaperPanelOpen = false
        }
        z: 0
    }
    
    // Main panel - centered below bar
    Rectangle {
        id: panelContent
        z: 1
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 65
        
        width: Math.min(950, parent.width - 80)
        height: 580
        
        color: theme.bg
        radius: 20
        border.color: Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.15)
        border.width: 2
        
        opacity: globalState.wallpaperPanelOpen ? 1 : 0
        scale: globalState.wallpaperPanelOpen ? 1 : 0.95
        
        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                
                Rectangle {
                    width: 44
                    height: 44
                    radius: 12
                    color: Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.15)
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰋩"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 26
                        color: theme.purple
                    }
                }
                
                ColumnLayout {
                    spacing: 2
                    
                    Text {
                        text: "Wallpaper Selector"
                        font.pixelSize: 22
                        font.bold: true
                        color: theme.fg
                    }
                    
                    Text {
                        text: "Choose your desktop wallpaper"
                        font.pixelSize: 13
                        color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.6)
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Close button
                Rectangle {
                    width: 44
                    height: 44
                    radius: 12
                    color: closeArea.containsMouse ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.2) : Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.05)
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 20
                        color: closeArea.containsMouse ? theme.red : theme.fg
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                    
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: globalState.wallpaperPanelOpen = false
                    }
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.1)
            }
            
            // Search bar
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 12
                color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.03)
                border.color: searchInput.activeFocus ? theme.purple : Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.08)
                border.width: 2
                
                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    
                    Text {
                        text: ""
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 18
                        color: theme.purple
                    }
                    
                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        color: theme.fg
                        font.pixelSize: 14
                        selectByMouse: true
                        clip: true
                        
                        Text {
                            anchors.fill: parent
                            text: "Search wallpapers..."
                            color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.4)
                            font.pixelSize: parent.font.pixelSize
                            visible: !parent.text && !parent.activeFocus
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onTextChanged: {
                            filterText = text;
                            updateFiltered();
                        }
                        
                        Keys.onEscapePressed: {
                            text = "";
                            focus = false;
                        }
                        
                        Keys.onDownPressed: {
                            if (wallpaperGrid.count > 0) {
                                wallpaperGrid.forceActiveFocus();
                                if (wallpaperGrid.currentIndex < 0) {
                                    wallpaperGrid.currentIndex = 0;
                                }
                            }
                        }
                    }
                    
                    // Clear search button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: clearArea.containsMouse ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.15) : "transparent"
                        visible: searchInput.text !== ""
                        
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 14
                            color: theme.fg
                        }
                        
                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchInput.text = ""
                        }
                    }
                    
                    // Refresh button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 8
                        color: refreshArea.containsMouse ? Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.15) : Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.05)
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 18
                            color: theme.green
                            rotation: refreshArea.containsPress ? 180 : 0
                            
                            Behavior on rotation {
                                NumberAnimation { duration: 200 }
                            }
                        }
                        
                        MouseArea {
                            id: refreshArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.refreshWallpapersList()
                        }
                    }
                }
            }
            
            // Info bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text {
                    text: ""
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 14
                    color: theme.purple
                }
                
                Text {
                    text: filteredWallpapers.length + " wallpapers" + (filterText ? " (filtered from " + wallpapersList.length + ")" : "")
                    font.pixelSize: 13
                    font.bold: true
                    color: theme.fg
                }
                
                Rectangle {
                    width: 3
                    height: 3
                    radius: 1.5
                    color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.3)
                }
                
                Text {
                    text: wallpaperPath
                    font.pixelSize: 12
                    color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.5)
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }
            
            // Wallpaper grid
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                
                background: Rectangle {
                    color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.02)
                    radius: 12
                }
                
                GridView {
                    id: wallpaperGrid
                    anchors.fill: parent
                    anchors.margins: 12
                    
                    property int columns: 4
                    cellWidth: Math.floor((width - 24) / columns)
                    cellHeight: Math.floor(cellWidth * 0.7) + 40
                    
                    model: filteredWallpapers
                    clip: true
                    focus: true
                    keyNavigationEnabled: true
                    
                    cacheBuffer: 500
                    
                    // Keyboard navigation
                    Keys.onReturnPressed: {
                        if (currentIndex >= 0 && currentIndex < filteredWallpapers.length) {
                            var path = filteredWallpapers[currentIndex];
                            WallpaperService.changeWallpaper(path, undefined);
                            globalState.wallpaperPanelOpen = false;
                        }
                    }
                    
                    Keys.onEscapePressed: {
                        globalState.wallpaperPanelOpen = false;
                    }
                    
                    Keys.onUpPressed: {
                        if (currentIndex < columns) {
                            searchInput.forceActiveFocus();
                        } else {
                            moveCurrentIndexUp();
                        }
                    }
                    
                    // Auto-scroll to keep current item visible
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0) {
                            var row = Math.floor(currentIndex / columns);
                            var itemY = row * cellHeight;
                            var viewportTop = contentY;
                            var viewportBottom = viewportTop + height;
                            
                            if (itemY < viewportTop) {
                                contentY = Math.max(0, itemY - cellHeight);
                            } else if (itemY + cellHeight > viewportBottom) {
                                contentY = itemY + cellHeight - height + cellHeight;
                            }
                        }
                    }
                    
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 8
                        
                        contentItem: Rectangle {
                            radius: 4
                            color: Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.5)
                        }
                    }
                    
                    delegate: Item {
                        width: wallpaperGrid.cellWidth
                        height: wallpaperGrid.cellHeight
                        
                        required property string modelData
                        required property int index
                        
                        property string wallpaperPath: modelData
                        property string filename: wallpaperPath.split('/').pop()
                        property bool isSelected: (wallpaperPath === currentWallpaper)
                        property bool isCurrent: (wallpaperGrid.currentIndex === index)
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 8
                            radius: 14
                            color: theme.bg
                            clip: true
                            
                            border.color: {
                                if (isSelected) return theme.green;
                                if (isCurrent) return theme.purple;
                                return Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, hoverBorder.opacity);
                            }
                            border.width: isSelected || isCurrent ? 3 : 2
                            
                            scale: (hoverArea.containsMouse || isCurrent) ? 1.03 : 1
                            
                            Behavior on border.color {
                                ColorAnimation { duration: 200 }
                            }
                            
                            Behavior on scale {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                            
                            Rectangle {
                                id: hoverBorder
                                anchors.fill: parent
                                radius: 14
                                color: "transparent"
                                opacity: hoverArea.containsMouse ? 0.3 : 0
                                
                                Behavior on opacity {
                                    NumberAnimation { duration: 200 }
                                }
                            }
                            
                            Image {
                                id: wallpaperImage
                                anchors.fill: parent
                                anchors.margins: 3
                                source: "file://" + wallpaperPath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                                cache: false
                                
                                // Loading indicator
                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.6)
                                    visible: wallpaperImage.status === Image.Loading
                                    radius: 11
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰔟"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 28
                                        color: theme.purple
                                        
                                        SequentialAnimation on opacity {
                                            running: wallpaperImage.status === Image.Loading
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
                                            NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
                                        }
                                    }
                                }
                                
                                // Error indicator
                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.8)
                                    visible: wallpaperImage.status === Image.Error
                                    radius: 11
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 28
                                        color: theme.red
                                    }
                                }
                            }
                            
                            // Selected indicator
                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 8
                                width: 28
                                height: 28
                                radius: 14
                                color: theme.green
                                visible: isSelected
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: ""
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 16
                                    color: theme.bg
                                }
                            }
                            
                            // Name overlay with gradient
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 38
                                radius: 14
                                
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.3; color: Qt.rgba(0, 0, 0, 0.6) }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: 4
                                    text: filename
                                    color: "white"
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideMiddle
                                    width: parent.width - 24
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            
                            MouseArea {
                                id: hoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onClicked: {
                                    wallpaperGrid.currentIndex = index;
                                    WallpaperService.changeWallpaper(wallpaperPath, undefined);
                                    globalState.wallpaperPanelOpen = false;
                                }
                            }
                        }
                    }
                    
                    // Empty state
                    Item {
                        anchors.fill: parent
                        visible: filteredWallpapers.length === 0 && !WallpaperService.scanning
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12
                            
                            Text {
                                text: ""
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 48
                                color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.3)
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Text {
                                text: filterText ? "No matching wallpapers" : "No wallpapers found"
                                font.pixelSize: 16
                                font.bold: true
                                color: theme.fg
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Text {
                                text: filterText ? "Try a different search" : "Add images to " + wallpaperPath
                                font.pixelSize: 13
                                color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.6)
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    // Scanning state
                    Item {
                        anchors.fill: parent
                        visible: WallpaperService.scanning
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12
                            
                            Text {
                                text: "󰔟"
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 48
                                color: theme.purple
                                Layout.alignment: Qt.AlignHCenter
                                
                                SequentialAnimation on opacity {
                                    running: WallpaperService.scanning
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
                                    NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
                                }
                            }
                            
                            Text {
                                text: "Scanning wallpapers..."
                                font.pixelSize: 16
                                font.bold: true
                                color: theme.fg
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
