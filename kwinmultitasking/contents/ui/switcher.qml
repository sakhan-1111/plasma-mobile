/********************************************************************
 KWin - the KDE window manager
 This file is part of the KDE project.

Copyright (C) 2012, 2013 Martin Gräßlin <mgraesslin@kde.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************/
import QtQuick 2.0;
import QtQuick.Window 2.0;
import org.kde.plasma.core 2.0 as PlasmaCore;
import org.kde.plasma.components 2.0 as PlasmaComponents;
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons;
import org.kde.kwin 2.0 as KWin;

PlasmaCore.Dialog {
    id: dialog
    location: PlasmaCore.Types.Floating
    visible: false
    flags: Qt.X11BypassWindowManagerHint
    backgroundHints: PlasmaCore.Dialog.NoBackground

    mainItem: Item {
        width: workspace.virtualScreenSize.width
        height: workspace.virtualScreenSize.height

        PlasmaComponents.Button {
            z: 99
            text: "close"
            onClicked: dialog.visible = false;
        }
        GridView {
            id: view
            anchors.fill: parent
            cellWidth: units.gridUnit * 20
            cellHeight: units.gridUnit * 20 // (view.width / view.height)
            model: KWin.ClientModel {
                id: clientModel
                exclusions: KWin.ClientModel.NotAcceptingFocusExclusion
            }
            delegate: MouseArea {
                width: view.cellWidth
                height: view.cellHeight
                PlasmaComponents.ToolButton {
                    anchors.right: parent.right
                    iconSource: "window-close"
                    flat: false
                    onClicked: model.client.closeWindow()
                    visible: model.client.closeable
                }
                KWin.ThumbnailItem {
                    anchors.fill: parent
                    //parentWindow: dialog.windowId
                    client: model.client
                    brightness: (index == view.currentIndex) ? 1.0 : 0.4
                }
                onClicked: {
                    workspace.activeClient = model.client
                    dialog.visible = false
                }
            }
        }
    }

    Component.onCompleted: {
        KWin.registerWindow(dialog);
    }
}
