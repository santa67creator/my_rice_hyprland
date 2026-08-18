import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell.Wayland

PanelWindow {
    id: main

    // =========================
    // SETTINGS
    // =========================

    property int selectorHeight: 550

    property int animationDuration: 180

    // Size of wallpaper in center
    property real zoomScale: 1.0

    // Size of wallpapers on edges
    property real edgeScale: 0.35

    property int baseSpacing: 8

    // =========================

    implicitWidth: Screen.width
    implicitHeight: selectorHeight

    color: "transparent"

    aboveWindows: true
    exclusionMode: "Ignore"
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        Quickshell.execDetached([
            "bash",
            Quickshell.shellPath("cache.sh"),
            Quickshell.shellDir
        ])
    }

    FileView {
        path: Quickshell.shellPath("config.json")
        watchChanges: true

        onFileChanged: reload()

        JsonAdapter {
            id: configs

            property string wallpaper_path
            property string cache_path

            property int number_of_pictures

            property string border_color

            property int cache_batch_size
        }
    }

    FolderListModel {
        id: folderModel

        folder: "file://" + configs.wallpaper_path

        showDirs: false

        nameFilters: [
            "*.png",
            "*.jpg",
            "*.jpeg",
            "*.webp"
        ]

        sortField: FolderListModel.Name
    }

    ListView {
        id: list

        anchors.fill: parent

        focus: true

        model: folderModel

        orientation: ListView.Horizontal

        spacing: main.baseSpacing

        clip: true

        cacheBuffer: 1000

        property int selectedIndex: 0

        property real tileWidth:
            width / configs.number_of_pictures

        property real viewportCenterX:
            width / 2


        function clampIndex(i) {
            return Math.max(
                0,
                Math.min(
                    i,
                    count - 1
                )
            )
        }


        function clampX(x) {
            return Math.max(
                0,
                Math.min(
                    x,
                    contentWidth - width
                )
            )
        }


        function activateCurrent() {

            if (count <= 0)
                return

            const path =
                folderModel.get(
                    selectedIndex,
                    "filePath"
                )

            Quickshell.execDetached([
                "bash",
                Quickshell.shellPath("commands.sh"),
                path
            ])

            Qt.quit()
        }


        function centerOnIndex(i) {

            const target =
                i * (tileWidth + spacing)
                - width / 2
                + tileWidth / 2

            contentX = clampX(target)
        }


        function moveSelection(delta) {

            if (count <= 0)
                return

            selectedIndex =
                clampIndex(
                    selectedIndex + delta
                )

            centerOnIndex(selectedIndex)
        }


        Behavior on contentX {

            NumberAnimation {

                duration:
                    main.animationDuration

                easing.type:
                    Easing.OutCubic
            }
        }


        delegate: Item {

            id: delegateItem

            height:
                main.selectorHeight

            width:
                list.tileWidth

            property bool active:
                index === list.selectedIndex


            property real screenCenterX:
                x
                - list.contentX
                + width / 2


            property real distance:

                Math.abs(
                    screenCenterX
                    - list.viewportCenterX
                )


            property real normalized:

                Math.min(
                    1,
                    distance
                    / list.viewportCenterX
                )


            property real smoothValue: {

                const t =
                    1
                    - normalized

                return
                    t
                    * t
                    * (3 - 2 * t)
            }


            property real scaleFactor:

                main.edgeScale
                + (
                    main.zoomScale
                    - main.edgeScale
                )
                * smoothValue


            Item {

                id: content

                anchors.centerIn: parent

                width:
                    delegateItem.width
                    * delegateItem.scaleFactor

                height:
                    delegateItem.height
                    * delegateItem.scaleFactor


                Image {

                    id: img

                    anchors.fill: parent

                    fillMode:
                        Image.PreserveAspectCrop

                    asynchronous: true

                    cache: false

                    smooth: true

                    source:
                        "file://"
                        + configs.cache_path
                        + fileName


                    sourceSize.width:

                        list.tileWidth
                        * main.zoomScale

                    sourceSize.height:

                        main.selectorHeight


                    opacity:
                        delegateItem.active
                        ? 1.0
                        : 0.75


                    Behavior on opacity {

                        NumberAnimation {

                            duration: 120
                        }
                    }


                    Timer {

                        id: retryTimer

                        interval: 500

                        repeat: false


                        onTriggered: {

                            const oldSource =
                                img.source

                            img.source = ""

                            img.source =
                                oldSource
                        }
                    }


                    onStatusChanged: {

                        if (
                            status
                            === Image.Error
                        ) {

                            retryTimer.start()
                        }
                    }
                }


                Rectangle {

                    anchors.fill: parent

                    visible:
                        delegateItem.active

                    color:
                        "transparent"

                    border.width: 3

                    border.color:
                        configs.border_color
                }
            }


            MouseArea {

                anchors.fill: parent

                hoverEnabled: true


                onEntered: {

                    list.selectedIndex =
                        index

                    list.centerOnIndex(
                        index
                    )
                }


                onClicked: {

                    list.selectedIndex =
                        index

                    list.activateCurrent()
                }


                onWheel:
                    function(wheel) {

                        if (
                            wheel.angleDelta.y
                            < 0
                        ) {

                            list.moveSelection(
                                1
                            )

                        } else {

                            list.moveSelection(
                                -1
                            )
                        }

                        wheel.accepted =
                            true
                    }
            }
        }


        Keys.onPressed:
            function(event) {

                const big =
                    configs.number_of_pictures


                switch(event.key) {

                case Qt.Key_J:

                case Qt.Key_Right:

                    moveSelection(1)

                    break


                case Qt.Key_K:

                case Qt.Key_Left:

                    moveSelection(-1)

                    break


                case Qt.Key_D:

                    moveSelection(big)

                    break


                case Qt.Key_U:

                    moveSelection(-big)

                    break


                case Qt.Key_Return:

                case Qt.Key_Enter:

                case Qt.Key_Space:

                    activateCurrent()

                    break


                case Qt.Key_Escape:

                    Qt.quit()

                    break


                default:

                    return
                }

                event.accepted =
                    true
            }


        Component.onCompleted: {

            if (count > 0) {

                selectedIndex = 0

                centerOnIndex(0)
            }
        }
    }
}
