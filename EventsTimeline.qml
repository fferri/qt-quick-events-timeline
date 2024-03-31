import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property Component eventDelegate
    property int rows: 20
    property int columns: 400
    property real rowHeight: 25
    property real columnWidth: 12.5
    property bool debug: false
    property DragArea activeDragArea: null

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
        cursorShape: activeDragArea ? activeDragArea.mouseArea.cursorShape : undefined
        preventStealing: true // otherwise the ScrollView steals the drag
        onDoubleClicked: function(mouse) {
            var row = Math.floor(mouse.y / root.rowHeight)
            var column = Math.floor(mouse.x / root.columnWidth)
            var rowSpan = 1
            var columnSpan = 10
            root.add(row, column, rowSpan, columnSpan)
        }
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
                z: 1
                mouseArea.drag.axis: Drag.XAxis
                eventsTimeline: root

                function resetPos() {
                    width = Math.min(20, eventItem.width / 3)
                    height = eventItem.height
                    x = eventItem.x
                    y = eventItem.y
                }

                onDragEnd: eventItem.resetPos()
                onXChanged: {
                    var c = Math.round(x / root.columnWidth)
                    var dc = c - eventItem.column
                    eventItem.column += dc
                    eventItem.columnSpan -= dc
                }
            }

            DragArea {
                id: dragAreaEnd
                z: 1
                mouseArea.drag.axis: Drag.XAxis
                eventsTimeline: root

                function resetPos() {
                    width = Math.min(20, eventItem.width / 3)
                    height = eventItem.height
                    x = eventItem.x + eventItem.width - width
                    y = eventItem.y
                }

                onDragEnd: eventItem.resetPos()
                onXChanged: {
                    var c = Math.round((x + width) / root.columnWidth)
                    var cs = c - eventItem.column
                    eventItem.columnSpan = cs
                }
            }

            DragArea {
                id: dragAreaMiddle
                mouseArea.drag.axis: Drag.XAndYAxis
                eventsTimeline: root

                function resetPos() {
                    width = eventItem.width// - dragAreaStart.width - dragAreaEnd.width
                    height = eventItem.height
                    x = eventItem.x// + dragAreaStart.width
                    y = eventItem.y
                }

                onDragEnd: eventItem.resetPos()
                onXChanged: eventItem.column = Math.round(x / root.columnWidth)
                onYChanged: eventItem.row = Math.round(y / root.rowHeight)
            }

            function resetPos() {
                dragAreaStart.resetPos()
                dragAreaEnd.resetPos()
                dragAreaMiddle.resetPos()
            }

            Component.onCompleted: {
                dragAreaStart.parent = eventItem.parent
                dragAreaEnd.parent = eventItem.parent
                dragAreaMiddle.parent = eventItem.parent
                resetPos()
            }
        }
    }

    function add(row, column, rowSpan, columnSpan) {
        return eventComponent.createObject(root, {row, column, rowSpan, columnSpan})
    }
}
