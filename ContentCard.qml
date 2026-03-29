import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Rectangle {
    id: contentCard
    
    property var contentItem: null
    
    color: "#2a2a2a"
    border.color: mouseArea.containsMouse ? "#007acc" : "#444"
    border.width: 1
    radius: 8
    
    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        onClicked: {
            // Handle content selection/playback
            console.log("Selected:", contentItem ? contentItem.title : "Unknown")
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6
        
        // Poster/Thumbnail
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            color: "#1a1a1a"
            radius: 4
            
            Image {
                id: posterImage
                anchors.fill: parent
                anchors.margins: 2
                source: contentItem ? (contentItem.poster || "") : ""
                fillMode: Image.PreserveAspectCrop
                radius: 4
                
                Rectangle {
                    anchors.fill: parent
                    color: "#1a1a1a"
                    radius: 4
                    visible: posterImage.status !== Image.Ready
                    
                    Text {
                        anchors.centerIn: parent
                        text: "No Image"
                        color: "#666"
                        font.pixelSize: 10
                    }
                }
            }
            
            // Rating Badge
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                width: ratingText.width + 8
                height: 20
                color: getRatingColor(contentItem ? contentItem.rating : 0)
                radius: 10
                visible: contentItem && contentItem.rating
                
                Text {
                    id: ratingText
                    anchors.centerIn: parent
                    text: contentItem ? (contentItem.rating ? contentItem.rating.toFixed(1) : "") : ""
                    color: "#ffffff"
                    font.pixelSize: 9
                    font.bold: true
                }
            }
            
            // Year Badge
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 6
                width: yearText.width + 8
                height: 20
                color: "#333"
                radius: 10
                visible: contentItem && contentItem.year
                
                Text {
                    id: yearText
                    anchors.centerIn: parent
                    text: contentItem ? (contentItem.year || "") : ""
                    color: "#ffffff"
                    font.pixelSize: 9
                }
            }
        }
        
        // Title
        Text {
            Layout.fillWidth: true
            text: contentItem ? (contentItem.title || "Unknown Title") : ""
            color: "#ffffff"
            font.pixelSize: 12
            font.bold: true
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        
        // Tags Flow
        Flow {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 3
            
            Repeater {
                model: getDisplayTags()
                
                Rectangle {
                    width: tagText.width + 6
                    height: 16
                    color: getTagColor(modelData.category)
                    radius: 8
                    
                    Text {
                        id: tagText
                        anchors.centerIn: parent
                        text: modelData.tag
                        color: "#ffffff"
                        font.pixelSize: 8
                    }
                }
            }
        }
    }
    
    function getDisplayTags() {
        if (!contentItem) return []
        
        var tags = []
        
        // Add genre tags (max 2)
        if (contentItem.genres) {
            contentItem.genres.slice(0, 2).forEach(function(genre) {
                tags.push({category: "genre", tag: genre})
            })
        }
        
        // Add mood tags (max 1)
        if (contentItem.moods && contentItem.moods.length > 0) {
            tags.push({category: "mood", tag: contentItem.moods[0]})
        }
        
        // Add cinematography tags (max 1)
        if (contentItem.cinematography && contentItem.cinematography.length > 0) {
            tags.push({category: "cinematography", tag: contentItem.cinematography[0]})
        }
        
        return tags.slice(0, 4) // Max 4 tags total
    }
    
    function getTagColor(category) {
        var colors = {
            "genre": "#007acc",
            "mood": "#8e44ad",
            "cinematography": "#e67e22",
            "country": "#27ae60",
            "awards": "#f39c12"
        }
        return colors[category] || "#666"
    }
    
    function getRatingColor(rating) {
        if (rating >= 8.0) return "#27ae60" // Green
        if (rating >= 7.0) return "#f39c12" // Orange
        if (rating >= 6.0) return "#e67e22" // Dark Orange
        return "#e74c3c" // Red
    }
}