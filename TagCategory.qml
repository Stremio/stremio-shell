import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Column {
    id: tagCategory
    spacing: 8
    
    property string title: ""
    property var tags: []
    property var selectedTags: []
    
    signal tagToggled(string tag, bool selected)
    
    Text {
        text: title
        color: "#ffffff"
        font.pixelSize: 14
        font.bold: true
    }
    
    Flow {
        width: parent.width
        spacing: 6
        
        Repeater {
            model: tagCategory.tags
            
            TagButton {
                tagText: modelData
                onToggled: function(selected) {
                    tagCategory.tagToggled(modelData, selected)
                }
            }
        }
    }
    
    function clearSelection() {
        for (var i = 0; i < tags.length; i++) {
            var tagButton = children[1].children[i]
            if (tagButton && tagButton.selected) {
                tagButton.selected = false
            }
        }
        selectedTags = []
    }
}