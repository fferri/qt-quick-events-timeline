import QtQuick
import QtQuick.Controls

ApplicationWindow {
    width: 640
    height: 480
    visible: true
    title: qsTr("Events Timeline")

    Component {
        id: horizontalGrid

        Item {
            id: horizontalGridItem

            Repeater {
                model: [1, 4, 16]

                GridLines {
                    anchors.fill: horizontalGridItem
                    cells: timeline.columns
                    cellSize: timeline.columnWidth
                    division: modelData
                    color: Qt.rgba(0, 0, 0, modelData / 16)
                }
            }
        }
    }

    Component {
        id: verticalGrid

        Item {
            id: verticalGridItem

            Repeater {
                model: [1, 10]

                GridLines {
                    anchors.fill: verticalGridItem
                    orientation: Qt.Vertical
                    cells: timeline.rows
                    cellSize: timeline.rowHeight
                    division: modelData
                    color: Qt.rgba(0, 0, 0, modelData / 10 / 4)
                }
            }
        }
    }

    SplitView {
        id: splitView
        anchors.fill: parent

        Item {
            SplitView.minimumWidth: 60
            SplitView.preferredWidth: 70
            SplitView.maximumWidth: 200

            ScrollView {
                id: verticalHeader
                anchors.fill: parent
                anchors.topMargin: horizontalHeader.height
                contentWidth: width
                contentHeight: timeline.height
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.position: timelineScrollView.ScrollBar.vertical.position

                Loader {
                    sourceComponent: verticalGrid
                    width: verticalHeader.width
                    height: timeline.height
                }

                Column {
                    Repeater {
                        model: timeline.rows
                        delegate: Text {
                            width: verticalHeader.width
                            height: timeline.rowHeight
                            text: `Track ${index+1}`
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: verticalHeader
                property point lastMousePos
                onPressed: mouse => lastMousePos = Qt.point(mouse.x, mouse.y)
                onPositionChanged: function(mouse) {
                    var mousePos = Qt.point(mouse.x, mouse.y)
                    var mouseDelta = Qt.point(mousePos.x - lastMousePos.x, mousePos.y - lastMousePos.y)
                    lastMousePos = mousePos
                    timeline.zoomVertical(mouseDelta, timelineScrollView)
                }
            }
        }

        Item {
            ScrollView {
                id: horizontalHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 20
                contentWidth: timeline.width
                contentHeight: height
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                ScrollBar.horizontal.position: timelineScrollView.ScrollBar.horizontal.position

                Loader {
                    sourceComponent: horizontalGrid
                    width: timeline.width
                    height: horizontalHeader.height
                }
            }

            MouseArea {
                anchors.fill: horizontalHeader
                property point lastMousePos
                onPressed: mouse => lastMousePos = Qt.point(mouse.x, mouse.y)
                onPositionChanged: function(mouse) {
                    var mousePos = Qt.point(mouse.x, mouse.y)
                    var mouseDelta = Qt.point(mousePos.x - lastMousePos.x, mousePos.y - lastMousePos.y)
                    lastMousePos = mousePos
                    timeline.zoomHorizontal(mouseDelta, timelineScrollView)
                }
            }

            ScrollView {
                id: timelineScrollView
                anchors.fill: parent
                anchors.topMargin: horizontalHeader.height
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                EventsTimeline {
                    id: timeline
                    backgroundDelegate: Rectangle {
                        id: background
                        color: 'gray'

                        Loader {
                            sourceComponent: horizontalGrid
                            anchors.fill: background
                        }

                        Loader {
                            sourceComponent: verticalGrid
                            anchors.fill: background
                        }
                    }
                    eventDelegate: Rectangle {
                        id: delegateRect
                        property bool selected
                        property color color: selected ? 'blue' : 'yellow'
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop {position: 0; color: delegateRect.color}
                            GradientStop {position: 1; color: Qt.darker(delegateRect.color)}
                        }
                        border.color: 'black'
                        border.width: 1
                        radius: 4
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        timeline.add(2, 10, 1, 10)
        timeline.add(3, 15, 1, 20)
        timeline.add(5, 5, 1, 10)
    }
}
