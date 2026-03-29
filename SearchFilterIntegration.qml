import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

// Integration example showing how to add search filters to existing Stremio UI
Item {
    id: searchIntegration
    
    property bool filterPanelVisible: false
    property var webView: null // Reference to the main WebEngineView
    
    // Toggle button for showing/hiding filter panel
    Rectangle {
        id: filterToggle
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 16
        width: 120
        height: 36
        color: filterPanelVisible ? "#007acc" : "#444"
        border.color: "#666"
        border.width: 1
        radius: 18
        z: 1000
        
        Row {
            anchors.centerIn: parent
            spacing: 6
            
            Text {
                text: "🔍"
                color: "#ffffff"
                font.pixelSize: 14
            }
            
            Text {
                text: "Filters"
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: filterPanelVisible
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                filterPanelVisible = !filterPanelVisible
                filterPanel.visible = filterPanelVisible
            }
        }
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }
    
    // Sliding filter panel
    Rectangle {
        id: filterPanel
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 320
        color: "#1a1a1a"
        border.color: "#333"
        border.width: 1
        visible: false
        z: 999
        
        // Slide animation
        transform: Translate {
            id: slideTransform
            x: filterPanel.visible ? 0 : filterPanel.width
            
            Behavior on x {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }
        
        SearchFilter {
            id: searchFilter
            anchors.fill: parent
            anchors.margins: 1
            
            onFiltersChanged: function(filters) {
                // Send filter data to web UI via WebChannel
                if (webView && webView.webChannel) {
                    webView.runJavaScript(`
                        if (window.stremioFilters) {
                            window.stremioFilters.updateFilters(${JSON.stringify(filters)});
                        }
                    `);
                }
                
                // Also emit signal for QML handling
                searchIntegration.filtersUpdated(filters);
            }
        }
        
        // Close button
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            width: 24
            height: 24
            color: closeMouseArea.containsMouse ? "#666" : "transparent"
            radius: 12
            
            Text {
                anchors.centerIn: parent
                text: "×"
                color: "#ffffff"
                font.pixelSize: 16
                font.bold: true
            }
            
            MouseArea {
                id: closeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    filterPanelVisible = false
                    filterPanel.visible = false
                }
            }
        }
    }
    
    // Overlay to close panel when clicking outside
    MouseArea {
        anchors.fill: parent
        visible: filterPanelVisible
        onClicked: {
            filterPanelVisible = false
            filterPanel.visible = false
        }
        z: 998
    }
    
    // Signals for external handling
    signal filtersUpdated(var filters)
    
    // Functions for external control
    function showFilters() {
        filterPanelVisible = true
        filterPanel.visible = true
    }
    
    function hideFilters() {
        filterPanelVisible = false
        filterPanel.visible = false
    }
    
    function setWebView(webViewRef) {
        webView = webViewRef
    }
    
    function clearFilters() {
        searchFilter.clearAllFilters()
    }
}

/*
Usage in main.qml:

1. Add to the main ApplicationWindow:

SearchFilterIntegration {
    id: searchFilterIntegration
    anchors.fill: parent
    
    Component.onCompleted: {
        searchFilterIntegration.setWebView(webView)
    }
    
    onFiltersUpdated: function(filters) {
        // Handle filter updates
        console.log("Filters updated:", JSON.stringify(filters))
    }
}

2. Add JavaScript to web UI to handle filters:

window.stremioFilters = {
    updateFilters: function(filters) {
        // Apply filters to your content
        console.log("Received filters:", filters);
        
        // Example: Filter your content array
        var filtered = yourContentArray.filter(item => {
            // Apply search text
            if (filters.searchText) {
                var searchText = filters.searchText.toLowerCase();
                if (!item.title.toLowerCase().includes(searchText)) {
                    return false;
                }
            }
            
            // Apply tag filters
            if (filters.tags && filters.tags.length > 0) {
                // Your tag filtering logic
            }
            
            // Apply year range
            if (filters.yearRange) {
                var year = parseInt(item.year);
                if (year < filters.yearRange.min || year > filters.yearRange.max) {
                    return false;
                }
            }
            
            // Apply rating range
            if (filters.ratingRange) {
                var rating = parseFloat(item.rating);
                if (rating < filters.ratingRange.min || rating > filters.ratingRange.max) {
                    return false;
                }
            }
            
            return true;
        });
        
        // Update your UI with filtered content
        updateContentDisplay(filtered);
    }
};

3. Optional: Add keyboard shortcut in main.qml:

Shortcut {
    sequence: "Ctrl+F"
    onActivated: searchFilterIntegration.showFilters()
}
*/