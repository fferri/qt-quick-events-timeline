import QtQuick
import QtQuick.Controls

ApplicationWindow {
    width: 640
    height: 480
    visible: true
    title: qsTr("Events Timeline")

    ScrollView {
        anchors.fill: parent
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn

        EventsTimeline {
            id: timeline
            eventDelegate: Rectangle {
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop {position: 0; color: 'yellow'}
                    GradientStop {position: 1; color: Qt.darker('yellow')}
                }
                border.color: 'black'
                border.width: 1
                radius: 4
            }
        }
    }

    Component.onCompleted: {
        timeline.add(2, 10, 1, 10)
        timeline.add(3, 15, 1, 20)
        timeline.add(5, 5, 1, 10)
    }
}
