import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property Component eventDelegate
    property int rows: 20
    property int columns: 400
    property real rowHeight: 25
    property real columnWidth: 12.5

    implicitWidth: columns * columnWidth
    implicitHeight: rows * rowHeight
    width: implicitWidth
    height: implicitHeight

    color: 'gray'

    Canvas {
        id: grid
        anchors.fill: parent
        opacity: 0.1
        onPaint: {
            var ctx = getContext('2d')
            ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.3)
            for(var rowY = 0; rowY <= height; rowY += rowHeight) {
                ctx.moveTo(0, rowY)
                ctx.lineTo(width, rowY)
            }
            ctx.stroke()
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        preventStealing: true // otherwise the ScrollView steals the drag
        cursorShape: dragTarget.activeDragArea ? dragTarget.activeDragArea.cursorShape : undefined
        onDoubleClicked: function(mouse) {
            var props = {
                row: Math.floor(mouse.y / root.rowHeight),
                column: Math.floor(mouse.x / root.columnWidth),
                rowSpan: 1,
                columnSpan: 10,
            }
            eventComponent.createObject(root, props)
        }
    }

    Item {
        id: dragTarget
        property DragArea activeDragArea: null
    }

    Component {
        id: eventComponent

        Item {
            id: eventItem
            property int row
            property int column
            property int rowSpan
            property int columnSpan
            x: column * root.columnWidth
            y: row * root.rowHeight
            width: columnSpan * columnWidth
            height: rowSpan * rowHeight

            Loader {
                id: eventDelegateLoader
                anchors.fill: parent
                sourceComponent: eventDelegate
            }

            DragArea {
                id: dragAreaStart
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.min(20, parent.width / 3)
                drag.axis: Drag.XAxis
                globalMouseArea: mouseArea
                globalDragTarget: dragTarget
                container: root
                onDragged: function(origRow, origColumn, origRowSpan, origColumnSpan, deltaRow, deltaColumn) {
                    eventItem.column = origColumn + deltaColumn
                    eventItem.columnSpan = origColumnSpan - deltaColumn
                }
            }

            DragArea {
                id: dragAreaEnd
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.min(20, parent.width / 3)
                drag.axis: Drag.XAxis
                globalMouseArea: mouseArea
                globalDragTarget: dragTarget
                container: root
                onDragged: function(origRow, origColumn, origRowSpan, origColumnSpan, deltaRow, deltaColumn) {
                    eventItem.columnSpan = origColumnSpan + deltaColumn
                }
            }

            DragArea {
                id: dragAreaMiddle
                anchors.fill: parent
                anchors.leftMargin: dragAreaStart.width
                anchors.rightMargin: dragAreaEnd.width
                drag.axis: Drag.XAndYAxis
                globalMouseArea: mouseArea
                globalDragTarget: dragTarget
                container: root
                onDragged: function(origRow, origColumn, origRowSpan, origColumnSpan, deltaRow, deltaColumn) {
                    eventItem.column = origColumn + deltaColumn
                    eventItem.row = origRow + deltaRow
                }
            }
        }
    }

    function add(row, column, rowSpan, columnSpan) {
        return eventComponent.createObject(root, {row, column, rowSpan, columnSpan})
    }
}
