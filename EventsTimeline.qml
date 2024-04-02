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

    property int defaultNewEventColumnSpan: 4

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
            var columnSpan = defaultNewEventColumnSpan
            root.add(row, column, rowSpan, columnSpan)
        }
        onPressed: function(mouse) {
            selectionRectangle.a = selectionRectangle.b = Qt.point(mouse.x, mouse.y)
            root.selection = []
        }
        onPositionChanged: function(mouse) {
            if(!pressed) return
            selectionRectangle.b = Qt.point(mouse.x, mouse.y)
            var newSelection = root.getEventsInRect(selectionRectangle)
            if(newSelection.length !== root.selection.length || !newSelection.every((element, index) => element === root.selection[index]))
                root.selection = newSelection
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
                    item.dragAxis = Drag.XAxis
                }

                Connections {
                    target: dragAreaStart.item

                    function onDragEnd() {
                        var sel = root.selection.length > 0 ? root.selection : [eventItem]
                        for(var item of sel)
                            item.resetPos()
                    }

                    function onXChanged() {
                        var sel = root.selection.length > 0 ? root.selection : [eventItem]
                        var dcMin = Math.max(...sel.map(item => -item.column))
                        var dcMax = Math.min(...sel.map(item => item.columnSpan - 1))
                        var dc = Math.round(target.x / root.columnWidth) - eventItem.column
                        dc = Math.max(dcMin, Math.min(dcMax, dc))
                        for(var item of sel) {
                            item.column += dc
                            item.columnSpan -= dc
                        }
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
                    item.dragAxis = Drag.XAxis
                }

                Connections {
                    target: dragAreaEnd.item

                    function onDragEnd() {
                        var sel = root.selection.length > 0 ? root.selection : [eventItem]
                        for(var item of sel)
                            item.resetPos()
                    }

                    function onXChanged() {
                        var sel = root.selection.length > 0 ? root.selection : [eventItem]
                        var dcMin = Math.max(...sel.map(item => -item.columnSpan + 1))
                        var dcMax = Math.min(...sel.map(item => root.columns - item.column - item.columnSpan))
                        var dc = Math.round((target.x + target.width) / root.columnWidth) - eventItem.column - eventItem.columnSpan
                        dc = Math.max(dcMin, Math.min(dcMax, dc))
                        for(var item of sel)
                            item.columnSpan += dc
                        root.defaultNewEventColumnSpan = eventItem.columnSpan
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
                    item.width = eventItem.width
                    item.height = eventItem.height
                    item.x = eventItem.x
                    item.y = eventItem.y
                    item.leftMargin = Qt.binding(() => dragAreaStart.width)
                    item.rightMargin = Qt.binding(() => dragAreaEnd.width)
                }

                Connections {
                    target: dragAreaMiddle.item

                    function onDragEnd() {
                        var sel = root.selection.length > 0 ? root.selection : [eventItem]
                        for(var item of sel)
                            item.resetPos()
                    }

                    function onXChanged() {
                        var sel = root.selection.length > 0 ? root.selection : [eventItem]
                        var dcMin = Math.max(...sel.map(item => -item.column))
                        var dcMax = Math.min(...sel.map(item => root.columns - item.column - item.columnSpan))
                        var dc = Math.round(target.x / root.columnWidth) - eventItem.column
                        dc = Math.max(dcMin, Math.min(dcMax, dc))
                        for(var item of sel)
                            item.column += dc
                    }

                    function onYChanged() {
                        var sel = root.selection.length > 0 ? root.selection : [eventItem]
                        var drMin = Math.max(...sel.map(item => -item.row))
                        var drMax = Math.min(...sel.map(item => root.rows - item.row - item.rowSpan))
                        var dr = Math.round(target.y / root.rowHeight) - eventItem.row
                        dr = Math.max(drMin, Math.min(drMax, dr))
                        for(var item of sel)
                            item.row += dr
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

            property alias leftMargin: eventDragAreaMouseArea.anchors.leftMargin
            property alias rightMargin: eventDragAreaMouseArea.anchors.rightMargin

            signal dragStart()
            signal dragEnd()
            signal clicked()
            signal shiftClicked()

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

                Rectangle {
                    anchors.fill: parent
                    visible: root.debug
                    color: eventDragAreaMouseArea.drag.active ? Qt.rgba(1, 0, 0, 0.2) : 'transparent'
                    border.width: 1
                    border.color: 'red'
                }
            }
        }
    }

    function add(row, column, rowSpan, columnSpan) {
        return eventComponent.createObject(root, {row, column, rowSpan, columnSpan})
    }

    function getEventsInRect(rect) {
        var events = []
        for(var children of root.children) {
            if(children.event !== children) continue // not an 'event' Item
            if(!(
                    rect.x + rect.width < children.x ||
                    children.x + children.width < rect.x ||
                    rect.y + rect.height < children.y ||
                    children.y + children.height < rect.y
            ))
                events.push(children)
        }
        events.sort()
        return events
    }
}
