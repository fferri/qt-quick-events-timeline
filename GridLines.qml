import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property int orientation: Qt.Horizontal
    property int cells: 400
    property real cellSize: 12.5
    property int division: 1
    property color color: 'black'

    Repeater {
        model: 1 + Math.ceil(root.cells / root.division)

        Shape {
            id: shape
            readonly property real pos: index * root.division * root.cellSize
            x: root.orientation === Qt.Horizontal ? pos : 0
            y: root.orientation === Qt.Vertical ? pos : 0
            width: root.orientation === Qt.Vertical ? root.width : 1
            height: root.orientation === Qt.Horizontal ? root.height : 1

            ShapePath {
                strokeWidth: 1
                strokeColor: root.color

                startX: 0
                startY: 0
                PathLine {
                    x: root.orientation === Qt.Vertical ? root.width : 0
                    y: root.orientation === Qt.Horizontal ? root.height : 0
                }
            }
        }
    }
}
