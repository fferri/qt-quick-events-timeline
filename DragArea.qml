import QtQuick

Item {
    id: root

    property alias mouseArea: mouseArea
    required property var eventsTimeline

    Drag.active: mouseArea.drag.active
    Drag.onActiveChanged: if(Drag.active) dragStart(); else dragEnd()
    onDragStart: eventsTimeline.activeDragArea = root
    onDragEnd: eventsTimeline.activeDragArea = null

    signal dragStart()
    signal dragEnd()

    Rectangle {
        anchors.fill: parent
        visible: eventsTimeline.debug
        color: 'transparent'
        border.width: 1
        border.color: 'red'
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        drag.target: root
        cursorShape: {
            if(eventsTimeline.activeDragArea && eventsTimeline.activeDragArea !== root)
                return eventsTimeline.activeDragArea.mouseArea.cursorShape
            switch(drag.axis) {
                case Drag.XAndYAxis: return Qt.SizeAllCursor
                case Drag.XAxis: return Qt.SizeHorCursor
                case Drag.YAxis: return Qt.SizeVerCursor
                default: return Qt.ForbiddenCursor
            }
        }
    }
}
