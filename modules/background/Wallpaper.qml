import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../services"

Item {
    id: root
    anchors.fill: parent

    // Active wallpaper source
    property string source: ""
    property Image currentImage: img1
    
    // Get the screen name for this wallpaper instance
    property string screenName: screen ? screen.name : ""
    
    // Update wallpaper when service emits changes
    Connections {
        target: WallpaperService
        
        function onWallpaperChanged(changedScreenName, path) {
            if (changedScreenName === screenName) {
                console.log("[Wallpaper] Wallpaper changed for", screenName, "to", path);
                root.source = "file://" + path;
            }
        }
    }
    
    // Load initial wallpaper once service is initialized
    Connections {
        target: WallpaperService
        
        function onIsInitializedChanged() {
            if (WallpaperService.isInitialized && !root.source) {
                var wallpaper = WallpaperService.getWallpaper(screenName);
                if (wallpaper && wallpaper !== "") {
                    console.log("[Wallpaper] Loading initial wallpaper for", screenName, ":", wallpaper);
                    root.source = "file://" + wallpaper;
                }
            }
        }
    }
    
    Component.onCompleted: {
        // Try to load wallpaper if service is already initialized
        if (WallpaperService.isInitialized) {
            var wallpaper = WallpaperService.getWallpaper(screenName);
            if (wallpaper && wallpaper !== "") {
                console.log("[Wallpaper] Loading wallpaper for", screenName, ":", wallpaper);
                root.source = "file://" + wallpaper;
            }
        }
    }
    
    // Visual Double-Buffering
    onSourceChanged: {
        if (source === "") {
            currentImage = null;
        } else {
            var nextImage = (currentImage === img1) ? img2 : img1;
            nextImage.source = root.source;
        }
    }
    
    // --- Visuals (Placeholder & Images) ---
    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        visible: root.source === ""
        z: 10
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20
            
            Text {
                text: "☹"
                font.pixelSize: 64
                color: "#f38ba8"
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: "No wallpaper set"
                color: "#cdd6f4"
                font.bold: true
                font.pixelSize: 24
            }
            
            Text {
                text: "Open the wallpaper panel to select one"
                color: "#a6adc8"
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    Image {
        id: img1
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: (root.currentImage === img1) ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 500
            }
        }
        onStatusChanged: if (status === Image.Ready && root.currentImage !== img1 && source == root.source)
            root.currentImage = img1
    }

    Image {
        id: img2
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: (root.currentImage === img2) ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 500
            }
        }
        onStatusChanged: if (status === Image.Ready && root.currentImage !== img2 && source == root.source)
            root.currentImage = img2
    }
}
