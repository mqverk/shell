pragma Singleton
import Qt.labs.folderlistmodel
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Default wallpaper directory
    property string defaultDirectory: Quickshell.env("HOME") + "/Pictures/wallpapers"
    
    // Current wallpapers per screen (cache)
    property var currentWallpapers: ({})
    
    // List of wallpapers per screen
    property var wallpaperLists: ({})
    
    // Track scanning state
    property int scanningCount: 0
    readonly property bool scanning: (scanningCount > 0)
    
    // Initialization state
    property bool isInitialized: false
    property string wallpaperCacheFile: Quickshell.env("HOME") + "/.cache/mannu/wallpapers.json"
    
    // Default fallback wallpaper
    property string defaultWallpaper: ""
    
    // Signals for reactive UI updates
    signal wallpaperChanged(string screenName, string path)
    signal wallpaperListChanged(string screenName, int count)
    
    // Initialize the service
    function init() {
        console.log("[WallpaperService] Starting service");
        
        // Ensure cache directory exists
        dirCreator.running = true;
        
        // Load from cache after a brief delay to let directory creation complete
        Qt.callLater(loadFromCache);
        Qt.callLater(refreshWallpapersList);
    }
    
    // Process to create cache directory
    Process {
        id: dirCreator
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.cache/mannu"]
        running: false
    }
    
    // Load wallpapers from cache file
    function loadFromCache() {
        wallpaperCacheView.path = wallpaperCacheFile;
    }
    
    // FileView for cache persistence
    FileView {
        id: wallpaperCacheView
        path: ""
        
        adapter: JsonAdapter {
            id: wallpaperCacheAdapter
            property var wallpapers: ({})
            property string defaultWallpaper: ""
        }
        
        onLoaded: {
            root.currentWallpapers = wallpaperCacheAdapter.wallpapers || {};
            root.defaultWallpaper = wallpaperCacheAdapter.defaultWallpaper || "";
            console.log("[WallpaperService] Loaded wallpapers from cache:", Object.keys(root.currentWallpapers).length, "screens");
            root.isInitialized = true;
        }
        
        onLoadFailed: error => {
            console.log("[WallpaperService] Cache file doesn't exist or failed to load, starting with empty wallpapers");
            root.currentWallpapers = {};
            root.isInitialized = true;
        }
    }
    
    // Timer to debounce cache saves
    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: {
            wallpaperCacheAdapter.wallpapers = root.currentWallpapers;
            wallpaperCacheAdapter.defaultWallpaper = root.defaultWallpaper;
            wallpaperCacheView.writeAdapter();
            console.log("[WallpaperService] Saved wallpapers to cache file");
        }
    }
    
    // Get wallpaper for a specific screen
    function getWallpaper(screenName) {
        return currentWallpapers[screenName] || root.defaultWallpaper;
    }
    
    // Change wallpaper for screen(s)
    function changeWallpaper(path, screenName) {
        if (screenName !== undefined) {
            _setWallpaper(screenName, path);
        } else {
            // If no screenName specified, change for all screens
            for (var i = 0; i < Quickshell.screens.length; i++) {
                _setWallpaper(Quickshell.screens[i].name, path);
            }
        }
    }
    
    // Internal function to set wallpaper
    function _setWallpaper(screenName, path) {
        if (path === "" || path === undefined) {
            return;
        }
        
        if (screenName === undefined) {
            console.log("[WallpaperService] No screen specified");
            return;
        }
        
        // Check if wallpaper actually changed
        var oldPath = currentWallpapers[screenName] || "";
        var wallpaperChanged = (oldPath !== path);
        
        if (!wallpaperChanged) {
            return;
        }
        
        // Update cache directly
        currentWallpapers[screenName] = path;
        
        // Save to cache file with debounce
        saveTimer.restart();
        
        // Emit signal for this specific wallpaper change
        root.wallpaperChanged(screenName, path);
        
        console.log("[WallpaperService] Set wallpaper for", screenName, "to", path);
    }
    
    // Get list of wallpapers for a screen
    function getWallpapersList(screenName) {
        if (screenName != undefined && wallpaperLists[screenName] != undefined) {
            return wallpaperLists[screenName];
        }
        return [];
    }
    
    // Refresh the wallpapers list
    function refreshWallpapersList() {
        console.log("[WallpaperService] Refreshing wallpapers list");
        scanningCount = 0;
        
        // Force refresh by toggling each scanner's currentDirectory
        for (var i = 0; i < wallpaperScanners.count; i++) {
            var scanner = wallpaperScanners.objectAt(i);
            if (scanner) {
                // Capture scanner in closure
                (function(s) {
                    var directory = root.defaultDirectory;
                    // Trigger a change by setting to /tmp then back to actual directory
                    s.currentDirectory = "/tmp";
                    Qt.callLater(function() {
                        s.currentDirectory = directory;
                    });
                })(scanner);
            }
        }
    }
    
    // Instantiator to create FolderListModel for each monitor
    Instantiator {
        id: wallpaperScanners
        model: Quickshell.screens
        delegate: FolderListModel {
            property string screenName: modelData.name
            property string currentDirectory: root.defaultDirectory
            
            folder: "file://" + currentDirectory
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.webp", "*.bmp", "*.svg"]
            showDirs: false
            sortField: FolderListModel.Name
            
            // Watch for directory changes via property binding
            onCurrentDirectoryChanged: {
                folder = "file://" + currentDirectory;
            }
            
            onStatusChanged: {
                if (status === FolderListModel.Null) {
                    // Flush the list
                    root.wallpaperLists[screenName] = [];
                    root.wallpaperListChanged(screenName, 0);
                } else if (status === FolderListModel.Loading) {
                    // Flush the list
                    root.wallpaperLists[screenName] = [];
                    scanningCount++;
                } else if (status === FolderListModel.Ready) {
                    var files = [];
                    for (var i = 0; i < count; i++) {
                        var directory = root.defaultDirectory;
                        var filepath = directory + "/" + get(i, "fileName");
                        files.push(filepath);
                    }
                    
                    // Update the list
                    root.wallpaperLists[screenName] = files;
                    
                    scanningCount--;
                    console.log("[WallpaperService] List refreshed for", screenName, "count:", files.length);
                    root.wallpaperListChanged(screenName, files.length);
                }
            }
        }
    }
    
    Component.onCompleted: {
        init();
    }
}
