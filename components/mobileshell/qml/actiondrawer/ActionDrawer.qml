/*
 *   SPDX-FileCopyrightText: 2014 Marco Martin <notmart@gmail.com>
 *   SPDX-FileCopyrightText: 2021 Devin Lin <devin@kde.org>
 *
 *   SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2

import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.private.nanoshell 2.0 as NanoShell
import org.kde.plasma.private.mobileshell as MobileShell
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.private.mobileshell.quicksettingsplugin as QS

Item {
    id: root

    /**
     * The model for the notification widget.
     */
    property var notificationModel

    /**
     * The model type for the notification widget.
     */
    property var notificationModelType: MobileShell.NotificationsModelType.NotificationsModel

    /**
     * The model for the quick settings.
     */
    property var quickSettingsModel: QS.QuickSettingsModel {}

    /**
     * The notification settings object to be used in the notification widget.
     */
    property var notificationSettings

    /**
     * Whether actions should be subject to restricted permissions (ex. lockscreen).
     *
     * The permissionsRequested() signal emits when authentication is requested.
     */
    property bool restrictedPermissions: false

    /**
     * The amount of pixels moved by touch/mouse in the process of opening/closing the panel.
     */
    property real offset: 0

    /**
     * Whether the panel is being dragged.
     */
    property bool dragging: false

    /**
     * Whether the panel is open after touch/mouse release from the first opening swipe.
     */
    property bool opened: false

    /**
     * Whether the panel should open to pinned mode first, with a second stroke needed to full open.
     * Only applies to portrait mode.
     */
    property bool openToPinnedMode: true

    /**
     * Direction the panel is currently moving in.
     */
    property int direction: MobileShell.Direction.None

    /**
     * The notifications widget being shown. May be null.
     */
    property var notificationsWidget: contentContainerLoader.item.notificationsWidget

    /**
     * The mode of the action drawer (portrait or landscape).
     */
    property int mode: (height > width && width <= largePortraitThreshold) ? ActionDrawer.Portrait : ActionDrawer.Landscape

    /**
     * At some point, even if the screen is technically portrait, if we have a ton of width it'd be best to just show the landscape mode.
     */
    readonly property real largePortraitThreshold: Kirigami.Units.gridUnit * 35

    enum Mode {
        Portrait = 0,
        Landscape
    }

    /**
     * Emitted when the drawer has closed.
     */
    signal drawerClosed()

    /**
     * Emitted when the drawer has opened.
     */
    signal drawerOpened()

    /**
     * Emitted when permissions are requested (ex. unlocking the phone).
     *
     * Only gets emitted when restrictedPermissions is set to true.
     */
    signal permissionsRequested()

    /**
     * Runs the held notification action that was pending for authentication.
     *
     * Should be called by users if authentication is successful after permissionsRequested() was emitted.
     */
    signal runPendingNotificationAction()

    onOpenedChanged: {
        if (opened) swipeArea.focus = true;
    }

    property real oldOffset
    onOffsetChanged: {
        if (offset < 0) {
            offset = 0;
        }

        root.direction = (oldOffset === offset)
                            ? MobileShell.Direction.None
                            : (offset > oldOffset ? MobileShell.Direction.Down : MobileShell.Direction.Up);

        oldOffset = offset;

        // close panel immediately after panel is not shown, and the flickable is not being dragged
        if (opened && root.offset <= 0 && !swipeArea.moving && !closeAnim.running && !openAnim.running) {
            root.updateState();
            focus = false;
        }
    }

    function cancelAnimations() {
        closeAnim.stop();
        openAnim.stop();
    }

    function open() {
        cancelAnimations();
        if (openToPinnedMode) {
            openAnim.restart(); // go to pinned height
        } else {
            expandAnim.restart(); // go to maximized height
        }
    }

    function closeImmediately() {
        cancelAnimations();
        offset = 0;
        closeAnim.finished();
    }

    function close() {
        cancelAnimations();
        closeAnim.restart();
    }

    function expand() {
        cancelAnimations();
        expandAnim.restart();
    }

    function updateState() {
        cancelAnimations();
        let openThreshold = Kirigami.Units.gridUnit;

        if (root.offset <= 0) {
            // close immediately, so that we don't have to wait Kirigami.Units.longDuration
            root.visible = false;
            close();
        } else if (root.direction === MobileShell.Direction.None || !root.opened) {

            // if the panel has not been opened yet, run open animation only if drag passed threshold
            (root.offset < openThreshold) ? close() : open();

        } else if (root.offset > contentContainerLoader.maximizedQuickSettingsOffset) {
            // if drag has gone past the fully expanded view
            expand();
        } else if (root.offset > contentContainerLoader.minimizedQuickSettingsOffset) {
            // if drag is between pinned view and fully expanded view
            if (root.direction === MobileShell.Direction.Down) {
                expand();
            } else {
                // go back to pinned, or close if pinned mode is disabled
                openToPinnedMode ? open() : close();
            }

        } else if (root.direction === MobileShell.Direction.Down) {
            // if drag is between pinned view and open view, and dragging down
            open();
        } else {
            // if drag is between pinned view and open view, and dragging up
            close();
        }
    }
    Timer {
        id: updateStateTimer
        interval: 0
        onTriggered: updateState()
    }

    PropertyAnimation on offset {
        id: closeAnim
        duration: Kirigami.Units.veryLongDuration
        easing.type: Easing.OutExpo
        to: 0
        onFinished: {
            root.visible = false;
            root.opened = false;
        }
    }
    PropertyAnimation on offset {
        id: openAnim
        duration: Kirigami.Units.veryLongDuration
        easing.type: Easing.OutExpo
        to: contentContainerLoader.minimizedQuickSettingsOffset
        onFinished: root.opened = true
    }
    PropertyAnimation on offset {
        id: expandAnim
        duration: Kirigami.Units.veryLongDuration
        easing.type: Easing.OutExpo
        to: contentContainerLoader.maximizedQuickSettingsOffset
        onFinished: root.opened = true;
    }

    MobileShell.SwipeArea {
        id: swipeArea
        mode: MobileShell.SwipeArea.VerticalOnly
        anchors.fill: parent

        onSwipeStarted: {
            root.cancelAnimations();
            root.dragging = true;
        }
        onSwipeEnded: {
            root.dragging = false;
            root.updateState();
        }
        onSwipeMove: (totalDeltaX, totalDeltaY, deltaX, deltaY) => {
            root.offset += deltaY;
        }

        Loader {
            id: contentContainerLoader
            anchors.fill: parent

            property real minimizedQuickSettingsOffset: item ? item.minimizedQuickSettingsOffset : 0
            property real maximizedQuickSettingsOffset: item ? item.maximizedQuickSettingsOffset : 0

            asynchronous: true
            sourceComponent: root.mode == ActionDrawer.Portrait ? portraitContentContainer : landscapeContentContainer
        }

        Component {
            id: portraitContentContainer
            PortraitContentContainer {
                actionDrawer: root
                width: root.width
                height: root.height
                quickSettingsModel: root.quickSettingsModel
            }
        }

        Component {
            id: landscapeContentContainer
            LandscapeContentContainer {
                actionDrawer: root
                width: root.width
                height: root.height
                quickSettingsModel: root.quickSettingsModel
            }
        }
    }
}
