/*
 *  SPDX-FileCopyrightText: 2021 Marco Martin <mart@kde.org>
 *
 *   SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.14

import org.kde.plasma.core 2.0 as PlasmaCore

import ".." as Launcher

DragHandler {
    id: root
    yAxis.enabled: enabled
    xAxis.enabled: enabled
    property Flickable mainFlickable
    property Launcher.AppDrawer appDrawer
    signal snapPage

    enum ScrollDirection {
        None,
        Horizontal,
        Vertical
    }

    property real __initialMainFlickableX
    property int __scrollDirection: DragGestureHandler.None
    onTranslationChanged: {
        if (active) {
            if (root.appDrawer.offset > PlasmaCore.Units.gridUnit) {
                __scrollDirection = DragGestureHandler.Vertical;
                snapPage();
            } else if (Math.abs(mainFlickable.contentX - __initialMainFlickableX) > PlasmaCore.Units.gridUnit) {
                __scrollDirection = DragGestureHandler.Horizontal;
                root.appDrawer.close();
            }

            if (__scrollDirection !== DragGestureHandler.Horizontal) {
                root.appDrawer.offset = -translation.y;
            }
            if (__scrollDirection !== DragGestureHandler.Vertical) {
                mainFlickable.contentX = Math.min((mainFlickable.width * mainFlickable.totalPages) - mainFlickable.width, Math.max(0, __initialMainFlickableX - translation.x))
            }
        }
    }
    onActiveChanged: {
        if (active) {
            __initialMainFlickableX = mainFlickable.contentX;
        } else {
            __scrollDirection = DragGestureHandler.None;
            root.appDrawer.snapDrawerStatus();
            snapPage();
        }
    }
}

