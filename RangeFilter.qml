import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Column {
    id: rangeFilter
    spacing: 8
    
    property string title: ""
    property real minValue: 0
    property real maxValue: 100
    property real currentMin: 0
    property real currentMax: 100
    property real stepSize: 1
    property int decimals: 0
    
    signal rangeChanged(real min, real max)
    
    Text {
        text: title
        color: "#ffffff"
        font.pixelSize: 14
        font.bold: true
    }
    
    Row {
        width: parent.width
        spacing: 8
        
        Text {
            text: formatValue(currentMin)
            color: "#cccccc"
            font.pixelSize: 12
            width: 40
        }
        
        Rectangle {
            width: parent.width - 100
            height: 20
            color: "#3a3a3a"
            radius: 10
            
            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                x: minHandle.x + minHandle.width/2
                width: maxHandle.x - minHandle.x
                height: 4
                color: "#007acc"
                radius: 2
            }
            
            Rectangle {
                id: minHandle
                width: 16
                height: 16
                radius: 8
                color: minMouseArea.pressed ? "#0099ff" : "#007acc"
                border.color: "#ffffff"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
                
                x: (currentMin - minValue) / (maxValue - minValue) * (parent.width - width)
                
                MouseArea {
                    id: minMouseArea
                    anchors.fill: parent
                    drag.target: parent
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: maxHandle.x - parent.width
                    
                    onPositionChanged: {
                        if (drag.active) {
                            var newMin = minValue + (parent.x / (parent.parent.width - parent.width)) * (maxValue - minValue)
                            newMin = Math.max(minValue, Math.min(newMin, currentMax - stepSize))
                            newMin = Math.round(newMin / stepSize) * stepSize
                            
                            if (newMin !== currentMin) {
                                currentMin = newMin
                                rangeChanged(currentMin, currentMax)
                            }
                        }
                    }
                }
            }
            
            Rectangle {
                id: maxHandle
                width: 16
                height: 16
                radius: 8
                color: maxMouseArea.pressed ? "#0099ff" : "#007acc"
                border.color: "#ffffff"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
                
                x: (currentMax - minValue) / (maxValue - minValue) * (parent.width - width)
                
                MouseArea {
                    id: maxMouseArea
                    anchors.fill: parent
                    drag.target: parent
                    drag.axis: Drag.XAxis
                    drag.minimumX: minHandle.x + minHandle.width
                    drag.maximumX: parent.parent.width - parent.width
                    
                    onPositionChanged: {
                        if (drag.active) {
                            var newMax = minValue + (parent.x / (parent.parent.width - parent.width)) * (maxValue - minValue)
                            newMax = Math.max(currentMin + stepSize, Math.min(newMax, maxValue))
                            newMax = Math.round(newMax / stepSize) * stepSize
                            
                            if (newMax !== currentMax) {
                                currentMax = newMax
                                rangeChanged(currentMin, currentMax)
                            }
                        }
                    }
                }
            }
        }
        
        Text {
            text: formatValue(currentMax)
            color: "#cccccc"
            font.pixelSize: 12
            width: 40
        }
    }
    
    function formatValue(value) {
        return decimals > 0 ? value.toFixed(decimals) : Math.round(value).toString()
    }
    
    function reset() {
        currentMin = minValue
        currentMax = maxValue
        rangeChanged(currentMin, currentMax)
    }
}