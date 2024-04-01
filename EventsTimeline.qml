import QtQuick
import QtQuick.Controls

Item {
    id: root

    property Component eventDelegate
    property int rows: 20
    property int columns: 400
    property real rowHeight: 25
    property real columnWidth: 12.5
    property bool debug: false

    // XXX: to avoid cursorShape flicker when dragging an mouse can go beyond the edge
    //      of the currently active mouseArea"
    property MouseArea activeDragMouseArea: null

    implicitWidth: columns * columnWidth
    implicitHeight: rows * rowHeight
    width: implicitWidth
    height: implicitHeight

    property var selection: []

    property Component backgroundDelegate: Component {
        Rectangle {
            color: 'gray'
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: backgroundDelegate
    }

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
        cursorShape: activeDragMouseArea?.cursorShape
        preventStealing: true // otherwise the ScrollView steals the drag
        onDoubleClicked: function(mouse) {
            var row = Math.floor(mouse.y / root.rowHeight)
            var column = Math.floor(mouse.x / root.columnWidth)
            var rowSpan = 1
            var columnSpan = 10
            root.add(row, column, rowSpan, columnSpan)
        }
        onPressed: function(mouse) {
            selectionRectangle.a = selectionRectangle.b = Qt.point(mouse.x, mouse.y)
            root.selection = []
        }
        onPositionChanged: function(mouse) {
            if(pressed) {
                selectionRectangle.b = Qt.point(mouse.x, mouse.y)
                selectionRectangle.updateSelection()
            }
        }
        onReleased: function(mouse) {
            selectionRectangle.a = selectionRectangle.b
        }
    }

    Rectangle {
        id: selectionRectangle
        color: Qt.rgba(0, 0.5, 1, 0.2)
        border.color: Qt.rgba(0, 0.5, 1, 1)
        border.width: 1
        property point a
        property point b
        x: Math.min(a.x, b.x)
        y: Math.min(a.y, b.y)
        width: Math.abs(a.x - b.x)
        height: Math.abs(a.y - b.y)
        z: 2

        function overlapsItem(item) {
            if(x + width < item.x || item.x + item.width < x)
                return false
            if(y + height < item.y || item.y + item.height < y)
                return false
            return true
        }

        function updateSelection() {
            var newSelection = []
            for(var children of root.children) {
                if(children.event === children && overlapsItem(children))
                    newSelection.push(children)
            }
            newSelection.sort()

            if(newSelection.length !== root.selection.length || !newSelection.every((element, index) => element === root.selection[index]))
                root.selection = newSelection
        }
    }

    Component {
        id: eventComponent

        Item {
            id: eventItem
            property var event: eventItem
            property int row
            property int column
            property int rowSpan
            property int columnSpan
            readonly property bool selected: root.selection.includes(eventItem)
            x: column * root.columnWidth
            y: row * root.rowHeight
            width: columnSpan * columnWidth
            height: rowSpan * rowHeight

            onSelectedChanged: if(eventDelegateLoader.item.selected !== undefined) eventDelegateLoader.item.selected = selected

            Loader {
                id: eventDelegateLoader
                anchors.fill: parent
                sourceComponent: eventDelegate
            }

            Loader {
                id: dragAreaStart
                sourceComponent: eventDragAreaComponent

                function resetPos() {
                    item.parent = eventItem.parent
                    item.width = Math.min(20, eventItem.width / 3)
                    item.height = eventItem.height
                    item.x = eventItem.x
                    item.y = eventItem.y
                    item.z = 1
                    item.dragAxis = Drag.XAxis
                }

                Connections {
                    target: dragAreaStart.item

                    function onDragEnd() {
                        eventItem.resetPos()
                    }

                    function onXChanged() {
                        var c = Math.round(target.x / root.columnWidth)
                        var dc = c - eventItem.column
                        dc = Math.max(-eventItem.column, Math.min(root.columns - eventItem.column, eventItem.columnSpan - 1, dc))
                        eventItem.column += dc
                        eventItem.columnSpan -= dc
                    }
                }

                onLoaded: resetPos()
            }

            Loader {
                id: dragAreaEnd
                sourceComponent: eventDragAreaComponent

                function resetPos() {
                    item.parent = eventItem.parent
                    item.width = Math.min(20, eventItem.width / 3)
                    item.height = eventItem.height
                    item.x = eventItem.x + eventItem.width - width
                    item.y = eventItem.y
                    item.z = 1
                    item.dragAxis = Drag.XAxis
                }

                Connections {
                    target: dragAreaEnd.item

                    function onDragEnd() {
                        eventItem.resetPos()
                    }

                    function onXChanged() {
                        var c = Math.round((target.x + target.width) / root.columnWidth)
                        var cs = c - eventItem.column
                        eventItem.columnSpan = Math.max(1, Math.min(root.columns - eventItem.column, cs))
                    }
                }

                onLoaded: resetPos()
            }

            Loader {
                id: dragAreaMiddle
                sourceComponent: eventDragAreaComponent
                property int dragAxis: Drag.XAndYAxis

                function resetPos() {
                    item.parent = eventItem.parent
                    item.width = eventItem.width// - dragAreaStart.width - dragAreaEnd.width
                    item.height = eventItem.height
                    item.x = eventItem.x// + dragAreaStart.width
                    item.y = eventItem.y
                }

                Connections {
                    target: dragAreaMiddle.item

                    function onDragEnd() {
                        eventItem.resetPos()
                    }

                    function onXChanged() {
                        eventItem.column = Math.max(0, Math.min(root.columns - eventItem.columnSpan, Math.round(target.x / root.columnWidth)))
                    }

                    function onYChanged() {
                        eventItem.row = Math.max(0, Math.min(root.rows - 1, Math.round(target.y / root.rowHeight)))
                    }

                    function onClicked() {
                        root.selection = [eventItem]
                    }

                    function onShiftClicked() {
                        if(root.selection.includes(eventItem))
                            root.selection = root.selection.filter(x => x !== eventItem)
                        else
                            root.selection = root.selection.concat([eventItem])
                    }
                }

                onLoaded: resetPos()
            }

            function resetPos() {
                dragAreaStart.resetPos()
                dragAreaEnd.resetPos()
                dragAreaMiddle.resetPos()
            }
        }
    }

    Component {
        id: eventDragAreaComponent

        Item {
            id: eventDragArea

            Drag.active: eventDragAreaMouseArea.drag.active
            Drag.onActiveChanged: if(Drag.active) dragStart(); else dragEnd()
            onDragStart: root.activeDragMouseArea = eventDragAreaMouseArea
            onDragEnd: root.activeDragMouseArea = null

            property int dragAxis: Drag.XAndYAxis

            signal dragStart()
            signal dragEnd()
            signal clicked()
            signal shiftClicked()

            Rectangle {
                anchors.fill: parent
                visible: root.debug
                color: 'transparent'
                border.width: 1
                border.color: 'red'
            }

            MouseArea {
                id: eventDragAreaMouseArea
                anchors.fill: parent
                drag.target: eventDragArea
                drag.axis: eventDragArea.dragAxis
                acceptedButtons: Qt.LeftButton
                cursorShape: {
                    if(root.activeDragMouseArea && root.activeDragMouseArea !== eventDragAreaMouseArea)
                        return root.activeDragMouseArea.cursorShape
                    switch(drag.axis) {
                        case Drag.XAndYAxis: return Qt.SizeAllCursor
                        case Drag.XAxis: return Qt.SizeHorCursor
                        case Drag.YAxis: return Qt.SizeVerCursor
                        default: return Qt.ForbiddenCursor
                    }
                }
                onClicked: function(mouse) {
                    if(mouse.modifiers & Qt.ShiftModifier)
                        eventDragArea.shiftClicked()
                    else
                        eventDragArea.clicked()
                }
            }
        }
    }

    function add(row, column, rowSpan, columnSpan) {
        return eventComponent.createObject(root, {row, column, rowSpan, columnSpan})
    }
}
