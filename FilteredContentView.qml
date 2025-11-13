import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import "searchFilterEngine.js" as FilterEngine

Rectangle {
    id: contentView
    color: "#0c0b11"
    
    property var contentData: []
    property var filteredData: []
    property var filterEngine: null
    
    Component.onCompleted: {
        filterEngine = new FilterEngine.SearchFilterEngine()
        filterEngine.setOnFilterChange(function(filtered, filters) {
            filteredData = filtered
            updateContentDisplay()
        })
    }
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // Filter Panel
        Rectangle {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            color: "#1a1a1a"
            border.color: "#333"
            border.width: 1
            
            SearchFilter {
                id: searchFilter
                anchors.fill: parent
                anchors.margins: 1
                
                onFiltersChanged: function(filters) {
                    if (filterEngine) {
                        filterEngine.updateFilters(filters)
                    }
                }
            }
        }
        
        // Content Display Area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0c0b11"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16
                
                // Filter Summary Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: "#1a1a1a"
                    border.color: "#333"
                    border.width: 1
                    radius: 4
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        
                        Text {
                            id: summaryText
                            text: "Showing " + filteredData.length + " of " + contentData.length + " items"
                            color: "#ffffff"
                            font.pixelSize: 12
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Text {
                            id: activeFiltersText
                            text: getActiveFiltersText()
                            color: "#888"
                            font.pixelSize: 11
                        }
                    }
                }
                
                // Content Grid
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    GridView {
                        id: contentGrid
                        anchors.fill: parent
                        cellWidth: 200
                        cellHeight: 300
                        model: filteredData
                        
                        delegate: ContentCard {
                            width: contentGrid.cellWidth - 10
                            height: contentGrid.cellHeight - 10
                            contentItem: modelData
                        }
                    }
                }
            }
        }
    }
    
    function setContent(content) {
        contentData = content
        if (filterEngine) {
            filterEngine.setContent(content)
        }
    }
    
    function updateContentDisplay() {
        contentGrid.model = filteredData
    }
    
    function getActiveFiltersText() {
        if (!filterEngine) return ""
        
        var summary = filterEngine.getFilterSummary()
        if (summary.activeFilters === 0) {
            return "No filters active"
        }
        
        var parts = []
        if (summary.filterDetails.search) {
            parts.push("Search: \"" + summary.filterDetails.search + "\"")
        }
        if (summary.filterDetails.tags) {
            parts.push(summary.filterDetails.tags + " tags")
        }
        if (summary.filterDetails.yearRange) {
            var yr = summary.filterDetails.yearRange
            parts.push("Years: " + yr.min + "-" + yr.max)
        }
        if (summary.filterDetails.ratingRange) {
            var rt = summary.filterDetails.ratingRange
            parts.push("Rating: " + rt.min.toFixed(1) + "-" + rt.max.toFixed(1))
        }
        
        return parts.join(" | ")
    }
}