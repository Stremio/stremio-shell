import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Rectangle {
    id: searchFilter
    color: "#1a1a1a"
    border.color: "#333"
    border.width: 1
    radius: 8
    
    property var selectedTags: []
    property var availableTags: {
        "genres": ["sci-fi", "drama", "comedy", "action", "thriller", "horror", "romance", "documentary"],
        "moods": ["existential", "uplifting", "dark", "mysterious", "intense", "light-hearted"],
        "cinematography": ["slow burn", "fast-paced", "neo-noir", "minimalist", "epic", "intimate"],
        "countries": ["USA", "UK", "France", "Japan", "South Korea", "Germany", "Italy", "Spain"],
        "awards": ["Oscar Winner", "Emmy Winner", "Golden Globe", "Cannes", "Sundance", "BAFTA"]
    }
    property var yearRange: { "min": 1900, "max": 2024 }
    property var ratingRange: { "min": 0.0, "max": 10.0 }
    property string searchText: ""
    
    signal filtersChanged(var filters)
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Search Input
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "#2a2a2a"
            border.color: searchInput.activeFocus ? "#007acc" : "#444"
            border.width: 1
            radius: 4
            
            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.margins: 12
                color: "#ffffff"
                font.pixelSize: 14
                selectByMouse: true
                
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search movies and shows..."
                    color: "#888"
                    font.pixelSize: 14
                    visible: searchInput.text.length === 0
                }
                
                onTextChanged: {
                    searchFilter.searchText = text
                    searchFilter.emitFiltersChanged()
                }
            }
        }
        
        // Tag Categories
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                width: parent.width
                spacing: 16
                
                // Genre Tags
                TagCategory {
                    id: genreCategory
                    Layout.fillWidth: true
                    title: "Genres"
                    tags: searchFilter.availableTags.genres
                    onTagToggled: function(tag, selected) {
                        searchFilter.toggleTag("genre", tag, selected)
                    }
                }
                
                // Mood Tags
                TagCategory {
                    id: moodCategory
                    Layout.fillWidth: true
                    title: "Moods"
                    tags: searchFilter.availableTags.moods
                    onTagToggled: function(tag, selected) {
                        searchFilter.toggleTag("mood", tag, selected)
                    }
                }
                
                // Cinematography Tags
                TagCategory {
                    id: cinematographyCategory
                    Layout.fillWidth: true
                    title: "Cinematography Style"
                    tags: searchFilter.availableTags.cinematography
                    onTagToggled: function(tag, selected) {
                        searchFilter.toggleTag("cinematography", tag, selected)
                    }
                }
                
                // Country Tags
                TagCategory {
                    id: countryCategory
                    Layout.fillWidth: true
                    title: "Country"
                    tags: searchFilter.availableTags.countries
                    onTagToggled: function(tag, selected) {
                        searchFilter.toggleTag("country", tag, selected)
                    }
                }
                
                // Awards Tags
                TagCategory {
                    id: awardsCategory
                    Layout.fillWidth: true
                    title: "Awards"
                    tags: searchFilter.availableTags.awards
                    onTagToggled: function(tag, selected) {
                        searchFilter.toggleTag("awards", tag, selected)
                    }
                }
                
                // Year Range Filter
                RangeFilter {
                    id: yearFilter
                    Layout.fillWidth: true
                    title: "Release Year"
                    minValue: 1900
                    maxValue: 2024
                    currentMin: searchFilter.yearRange.min
                    currentMax: searchFilter.yearRange.max
                    onRangeChanged: function(min, max) {
                        searchFilter.yearRange = {"min": min, "max": max}
                        searchFilter.emitFiltersChanged()
                    }
                }
                
                // Rating Range Filter
                RangeFilter {
                    id: ratingFilter
                    Layout.fillWidth: true
                    title: "Rating (IMDb)"
                    minValue: 0.0
                    maxValue: 10.0
                    currentMin: searchFilter.ratingRange.min
                    currentMax: searchFilter.ratingRange.max
                    stepSize: 0.1
                    decimals: 1
                    onRangeChanged: function(min, max) {
                        searchFilter.ratingRange = {"min": min, "max": max}
                        searchFilter.emitFiltersChanged()
                    }
                }
            }
        }
        
        // Clear Filters Button
        Button {
            Layout.fillWidth: true
            height: 36
            text: "Clear All Filters"
            
            background: Rectangle {
                color: parent.pressed ? "#555" : "#444"
                border.color: "#666"
                border.width: 1
                radius: 4
            }
            
            contentItem: Text {
                text: parent.text
                color: "#ffffff"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: searchFilter.clearAllFilters()
        }
    }
    
    function toggleTag(category, tag, selected) {
        var tagObj = {"category": category, "tag": tag}
        var tagKey = category + ":" + tag
        
        if (selected) {
            selectedTags.push(tagObj)
        } else {
            selectedTags = selectedTags.filter(function(t) {
                return !(t.category === category && t.tag === tag)
            })
        }
        
        emitFiltersChanged()
    }
    
    function clearAllFilters() {
        selectedTags = []
        searchText = ""
        yearRange = {"min": 1900, "max": 2024}
        ratingRange = {"min": 0.0, "max": 10.0}
        
        searchInput.text = ""
        genreCategory.clearSelection()
        moodCategory.clearSelection()
        cinematographyCategory.clearSelection()
        countryCategory.clearSelection()
        awardsCategory.clearSelection()
        yearFilter.reset()
        ratingFilter.reset()
        
        emitFiltersChanged()
    }
    
    function emitFiltersChanged() {
        var filters = {
            "searchText": searchText,
            "tags": selectedTags,
            "yearRange": yearRange,
            "ratingRange": ratingRange
        }
        filtersChanged(filters)
    }
}