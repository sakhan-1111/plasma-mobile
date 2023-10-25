// SPDX-FileCopyrightText: 2023 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami 2.20 as Kirigami

import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.private.mobileshell 1.0 as MobileShell
import org.kde.private.mobile.homescreen.folio 1.0 as Folio

import '../delegate'

Item {
    id: root

    property var homeScreen
    property real settingsModeHomeScreenScale

    signal requestLeaveSettingsMode()

    MouseArea {
        id: closeSettings

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: settingsBar.top

        onClicked: {
            Folio.HomeScreenState.closeSettingsView();
        }
    }

    Item {
        id: settingsBar

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.height * (1 - settingsModeHomeScreenScale)

        RowLayout {
            id: settingsOptions
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            PC3.ToolButton {
                text: i18n('Wallpapers')
                enabled: false
                display: PC3.ToolButton.TextUnderIcon

                icon.name: 'edit-image'

                implicitHeight: Kirigami.Units.gridUnit * 4
                implicitWidth: Kirigami.Units.gridUnit * 5
            }

            PC3.ToolButton {
                text: ('Settings')
                display: PC3.ToolButton.TextUnderIcon

                icon.name: 'settings-configure'

                implicitHeight: Kirigami.Units.gridUnit * 4
                implicitWidth: Kirigami.Units.gridUnit * 5

                onClicked: {
                    // ensure that if the window is already opened, it gets raised to the top
                    settingsWindow.hide();
                    settingsWindow.showMaximized();
                }
            }

            PC3.ToolButton {
                text: 'Widgets'
                enabled: false
                display: PC3.ToolButton.TextUnderIcon

                icon.name: 'widget-alternatives'

                implicitHeight: Kirigami.Units.gridUnit * 4
                implicitWidth: Kirigami.Units.gridUnit * 5
            }
        }
    }

    SettingsWindow {
        id: settingsWindow
        visible: false

        onRequestConfigureMenu: {
            homeScreen.openConfigure()
        }
    }
}