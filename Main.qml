import QtQuick
import QtQuick.Controls

ApplicationWindow {
    width: 640
    height: 480
    visible: true
    title: qsTr("Events Timeline")

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

                Repeater {
                    model: [1, 10]

                    GridLines {
                        width: verticalHeader.width
                        height: timeline.height
                        orientation: Qt.Vertical
                        cells: timeline.rows
                        cellSize: timeline.rowHeight
                        division: modelData
                        color: Qt.rgba(0, 0, 0, modelData / 10)
                    }
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

                Repeater {
                    model: [1, 4, 16]

                    GridLines {
                        width: timeline.width
                        height: horizontalHeader.height
                        cells: timeline.columns
                        cellSize: timeline.columnWidth
                        division: modelData
                        color: Qt.rgba(0, 0, 0, modelData / 16)
                    }
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

                        Repeater {
                            model: [1, 4, 16]

                            GridLines {
                                id: horizontalGrid
                                anchors.fill: background
                                cells: timeline.columns
                                cellSize: timeline.columnWidth
                                division: modelData
                                color: Qt.rgba(0, 0, 0, modelData / 16)
                            }
                        }

                        Repeater {
                            model: [1, 10]

                            GridLines {
                                id: verticalGrid
                                orientation: Qt.Vertical
                                anchors.fill: background
                                cells: timeline.rows
                                cellSize: timeline.rowHeight
                                division: modelData
                                color: Qt.rgba(0, 0, 0, modelData / 10)
                            }
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
