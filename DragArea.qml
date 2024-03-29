import QtQuick

MouseArea {
    id: root

    cursorShape: {
        switch(drag.axis) {
            case Drag.XAndYAxis: return Qt.SizeAllCursor
            case Drag.XAxis: return Qt.SizeHorCursor
            case Drag.YAxis: return Qt.SizeVerCursor
            default: return Qt.ForbiddenCursor
        }
    }
    states: State {
        // XXX: keeps cursor shape fixed, as mouse can go over an adjacent drag region:
        when: globalDragTarget.activeDragArea && globalDragTarget.activeDragArea !== root
        PropertyChanges {
            target: root
            cursorShape: globalDragTarget.activeDragArea.cursorShape
        }
    }

    required property MouseArea globalMouseArea
    required property Item globalDragTarget
    required property var container

    signal dragged(origRow: int, origColumn: int, origRowSpan: int, origColumnSpan: int, deltaRow: int, deltaColumn: int)

    Connections {
        target: root

        function onPressed(mouse) {
            // clone root's geometry to globalDragTarget:
            var p = globalDragTarget.parent.mapFromItem(root, Qt.point(0, 0))
            globalDragTarget.x = p.x
            globalDragTarget.y = p.y
            globalDragTarget.width = root.width
            globalDragTarget.height = root.height
            globalDragTarget.activeDragArea = root

            // save the state at beginning of dragging:
            dragStartState.row = root.parent.row
            dragStartState.column = root.parent.column
            dragStartState.rowSpan = root.parent.rowSpan
            dragStartState.columnSpan = root.parent.columnSpan
            dragStartState.dragStartRow = Math.round(globalDragTarget.y / root.container.rowHeight)
            dragStartState.dragStartColumn = Math.round(globalDragTarget.x / root.container.columnWidth)
            dragStartState.active = true

            // XXX: reject event so the globalMouseArea handles it:
            mouse.accepted = false
            globalMouseArea.drag.axis = root.drag.axis
            globalMouseArea.drag.target = globalDragTarget
        }
    }

    Connections {
        target: globalMouseArea

        function onReleased(mouse) {
            // XXX: the released event is received via the globalMouseArea:
            dragStartState.active = false
            globalDragTarget.activeDragArea = null
        }
    }

    Connections {
        target: globalDragTarget
        enabled: dragStartState.active

        function onXChanged() {
            update()
        }

        function onYChanged() {
            update()
        }

        function update() {
            var row = Math.round(globalDragTarget.y / root.container.rowHeight) - dragStartState.dragStartRow
            var column = Math.round(globalDragTarget.x / root.container.columnWidth) - dragStartState.dragStartColumn
            root.dragged(dragStartState.row, dragStartState.column, dragStartState.rowSpan, dragStartState.columnSpan, row, column)
        }
    }

    QtObject {
        id: dragStartState

        property int row
        property int column
        property int rowSpan
        property int columnSpan
        property int dragStartRow
        property int dragStartColumn
        property bool active: false
    }
}
