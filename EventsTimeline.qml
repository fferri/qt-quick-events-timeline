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

                Connections {
                    target: dragAreaStart.item

                    function onXChanged() {
                        // just before dragActive becomes false, X/Y position is already changed to 0!
                        if(!dragAreaStart.item.dragActive) return

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

                onLoaded: {
                    item.dragAxis = Drag.XAxis
                    item.theItem = eventItem
                    item.alignLeft = true
                }
            }

            Loader {
                id: dragAreaEnd
                sourceComponent: eventDragAreaComponent

                Connections {
                    target: dragAreaEnd.item

                    function onXChanged() {
                        // just before dragActive becomes false, X/Y position is already changed to 0!
                        if(!dragAreaEnd.item.dragActive) return

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

                onLoaded: {
                    item.dragAxis = Drag.XAxis
                    item.theItem = eventItem
                    item.alignRight = true
                }
            }

            Loader {
                id: dragAreaMiddle
                sourceComponent: eventDragAreaComponent

                Connections {
                    target: dragAreaMiddle.item

                    function onXChanged() {
                        // just before dragActive becomes false, X/Y position is already changed to 0!
                        if(!dragAreaMiddle.item.dragActive) return

                        var sel = root.selection.length > 0 ? root.selection : [eventItem]
                        var dcMin = Math.max(...sel.map(item => -item.column))
                        var dcMax = Math.min(...sel.map(item => root.columns - item.column - item.columnSpan))
                        var dc = Math.round(target.x / root.columnWidth) - eventItem.column
                        dc = Math.max(dcMin, Math.min(dcMax, dc))
                        for(var item of sel)
                            item.column += dc
                    }

                    function onYChanged() {
                        // just before dragActive becomes false, X/Y position is already changed to 0!
                        if(!dragAreaMiddle.item.dragActive) return

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

                onLoaded: {
                    item.theItem = eventItem
                    item.leftMargin = Qt.binding(() => dragAreaStart.width)
                    item.rightMargin = Qt.binding(() => dragAreaEnd.width)
                }
            }
        }
    }

    Component {
        id: eventDragAreaComponent

        Item {
            id: eventDragArea

            Drag.active: eventDragAreaMouseArea.drag.active

            Binding {
                target: root
                property: 'activeDragMouseArea'
                value: eventDragAreaMouseArea
                when: dragActive
            }

            property int dragAxis: Drag.XAndYAxis
            property alias dragActive: eventDragAreaMouseArea.drag.active

            property alias leftMargin: eventDragAreaMouseArea.anchors.leftMargin
            property alias rightMargin: eventDragAreaMouseArea.anchors.rightMargin

            signal clicked()
            signal shiftClicked()

            property Item theItem
            property bool alignLeft
            property bool alignRight

            // following 4 to suppress the "Cannot read property 'xxx' of null" error
            readonly property real theItemX: theItem?.x || 0
            readonly property real theItemY: theItem?.y || 0
            readonly property real theItemWidth: theItem?.width || 0
            readonly property real theItemHeight: theItem?.height || 0

            // when drag is active, de-parent the item:
            x: dragActive ? theItemX : (alignRight ? theItemWidth - width : 0)
            y: dragActive ? theItemY : 0
            width: (alignLeft || alignRight) ? Math.min(20, theItemWidth / 3) : theItemWidth
            height: theItemHeight
            Binding on parent {when: dragActive; value: theItem.parent}

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

    function zoomHorizontal(mouseDelta: point, timelineScrollView: ScrollView) {
        var sb = timelineScrollView.ScrollBar.horizontal
        var newColumnWidth = root.columnWidth * Math.pow(2, mouseDelta.y / 200)
        var posDispl = (sb.position + sb.size / 2) * (newColumnWidth / root.columnWidth - 1)
        var hscroll = -mouseDelta.x / root.width
        root.columnWidth = newColumnWidth

        const minPos = 0, maxPos = 1 - timelineScrollView.ScrollBar.horizontal.size
        sb.position = Math.max(minPos, Math.min(maxPos, sb.position + posDispl + hscroll))
    }

    function zoomVertical(mouseDelta: point, timelineScrollView: ScrollView) {
        var sb = timelineScrollView.ScrollBar.vertical
        var newRowHeight = root.rowHeight * Math.pow(2, mouseDelta.x / 200)
        var posDispl = (sb.position + sb.size / 2) * (newRowHeight / root.rowHeight - 1)
        var vscroll = -mouseDelta.y / root.height
        root.rowHeight = newRowHeight

        const minPos = 0, maxPos = 1 - timelineScrollView.ScrollBar.vertical.size
        sb.position = Math.max(minPos, Math.min(maxPos, sb.position + posDispl + vscroll))
    }
}
