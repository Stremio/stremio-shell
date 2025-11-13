import QtQuick 2.7
import QtQuick.Controls 2.0

Rectangle {
    id: tagButton
    
    property string tagText: ""
    property bool selected: false
    property string tooltipText: getTooltipText(tagText)
    
    signal toggled(bool selected)
    
    width: tagLabel.width + 16
    height: 28
    radius: 14
    
    color: selected ? "#007acc" : "#3a3a3a"
    border.color: selected ? "#0099ff" : "#555"
    border.width: 1
    
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    Text {
        id: tagLabel
        anchors.centerIn: parent
        text: tagButton.tagText
        color: tagButton.selected ? "#ffffff" : "#cccccc"
        font.pixelSize: 11
        font.bold: tagButton.selected
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        onClicked: {
            tagButton.selected = !tagButton.selected
            tagButton.toggled(tagButton.selected)
        }
        
        onEntered: {
            if (tooltipText !== "") {
                tooltip.show()
            }
        }
        
        onExited: {
            tooltip.hide()
        }
    }
    
    // Tooltip
    Rectangle {
        id: tooltip
        visible: false
        width: tooltipLabel.width + 12
        height: tooltipLabel.height + 8
        color: "#2a2a2a"
        border.color: "#555"
        border.width: 1
        radius: 4
        z: 1000
        
        anchors.bottom: parent.top
        anchors.bottomMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        
        Text {
            id: tooltipLabel
            anchors.centerIn: parent
            text: tagButton.tooltipText
            color: "#ffffff"
            font.pixelSize: 10
            wrapMode: Text.WordWrap
        }
        
        function show() {
            if (tooltipText !== "") {
                visible = true
            }
        }
        
        function hide() {
            visible = false
        }
    }
    
    function getTooltipText(tag) {
        var tooltips = {
            "slow burn": "Films with deliberate pacing that build tension gradually",
            "neo-noir": "Modern films with classic noir elements: dark themes, moral ambiguity",
            "existential": "Explores questions about existence, meaning, and human condition",
            "minimalist": "Simple, stripped-down visual style with focus on essentials",
            "epic": "Grand scale productions with sweeping narratives",
            "intimate": "Character-driven stories with personal, emotional focus",
            "fast-paced": "Quick editing and rapid story progression",
            "uplifting": "Positive, inspiring content that elevates mood",
            "dark": "Serious, often disturbing themes and atmosphere",
            "mysterious": "Enigmatic plots with hidden elements to discover",
            "intense": "High emotional or physical stakes throughout",
            "light-hearted": "Fun, easy-going content without heavy themes",
            "Oscar Winner": "Academy Award winning films",
            "Emmy Winner": "Emmy Award winning television content",
            "Golden Globe": "Golden Globe Award winners",
            "Cannes": "Cannes Film Festival selections and winners",
            "Sundance": "Sundance Film Festival selections",
            "BAFTA": "British Academy Film Awards winners"
        }
        
        return tooltips[tag] || ""
    }
}