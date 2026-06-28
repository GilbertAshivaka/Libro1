import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
/*
  opacManager is initialized as rootContextProperty
*/

Page {
  id: opacConfigurationView
  title: "OPAC Configuration"
  anchors.fill: parent

  signal closeClicked()

  //MouseArea to prevent mouse actions from leaking to the screens under this
  MouseArea{
    id: opacConfigurationViewMA
    anchors.fill: parent
  }

  //close Button
  Rectangle{
    id: closeBtn
    width: 80
    height: 32
    radius: 25
    //            color: "#878585"
    border.color: "#878585"
    border.width: 2
    clip: true
    // x: parent.width - width +20
    // y: 10
    z:3 //have the highest z to be visible
    anchors{
      top: parent.top
      topMargin: 10
      right: parent.right
      rightMargin: 30
    }

    Text{
      id: closeBtnTxt
      anchors.centerIn: parent
      text: "Close"
      //                color: "white"
      font.pixelSize: 16
      font.bold: true
    }

    MouseArea{
      id: closeBtnMA
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      onEntered: {
        closeBtn.color = "#878585"
        closeBtnTxt.color = "white"
      }
      onExited: {
        closeBtn.color = "white"
        closeBtnTxt.color ="#878585"
      }

      onClicked:{
        closeClicked()
      }
    }
  }

  ScrollView {
      Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    ColumnLayout {
      width: parent.width
      spacing: 20

      // First-time setup instructions (shown when not configured)
      GroupBox {
        Layout.fillWidth: true
        Layout.margins: 20
        title: "⚠️ First-Time Setup Required"
        visible: !opacManager.isConfigured

        ColumnLayout {
          width: parent.width
          spacing: 10

          Label {
            text: "Before configuring the desktop app, you need to set up the OPAC server:"
            font.bold: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          Label {
            text: "1. Start the OPAC backend server (FastAPI)\n" +
                  "2. Open web browser to the server URL\n" +
                  "3. Complete the setup wizard to create admin account\n" +
                  "4. Generate an API key for this desktop application\n" +
                  "5. Copy the API key (shown only once!)\n" +
                  "6. Return here and enter the server URL and API key below"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          Label {
            text: "See documentation for detailed instructions"
            font.italic: true
            color: "#0066cc"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }
        }
      }

      // Connection Configuration Section
      GroupBox {
        Layout.fillWidth: true
        Layout.margins: 20
        title: "OPAC Configuration"

        ColumnLayout {
          width: parent.width
          spacing: 15

          // OPAC URL
          Label {
            text: "OPAC Server URL:"
            font.bold: true
          }

          TextField {
            id: opacUrlField
            Layout.fillWidth: true
            placeholderText: "http://localhost:8000 (or your server URL)"
            text: opacManager.isConfigured ? opacManager.getConfiguration()["opacUrl"] : ""
          }

          Label {
            text: "Example: http://localhost:8000 for local server or https://library.yourdomain.com for production"
            font.pixelSize: 10
            color: "gray"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          // API Key
          Label {
            text: "API Key:"
            font.bold: true
          }

          Label {
            text: "Get your API key from the OPAC web interface setup wizard or admin panel"
            font.pixelSize: 10
            color: "gray"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          RowLayout {
            Layout.fillWidth: true

            TextField {
              id: apiKeyField
              Layout.fillWidth: true
              placeholderText: "Enter API key from web setup"
              echoMode: showApiKeyCheckbox.checked ? TextInput.Normal : TextInput.Password
              text: opacManager.isConfigured ? opacManager.getConfiguration()["apiKey"] : ""
            }

            CheckBox {
              id: showApiKeyCheckbox
              text: "Show"
            }
          }

          // Connection Status
          Rectangle {
            id: connectionStatus
            Layout.fillWidth: true
            height: 40
            color: "#f0f0f0"
            radius: 5
            visible: connectionStatusText.text !== ""

            RowLayout {
              anchors.fill: parent
              anchors.margins: 10

              Rectangle {
                width: 12
                height: 12
                radius: 6
                color: connectionStatusColor
              }

              Label {
                id: connectionStatusText
                Layout.fillWidth: true
              }
            }
          }

          // Buttons
          RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
              text: "Test Connection"
              enabled: opacUrlField.text !== "" && apiKeyField.text !== ""
              onClicked: {
                connectionStatusText.text = "Testing..."
                connectionStatusColor = "gray"
                opacManager.testConnection()
              }
            }

            Button {
              text: opacManager.isConfigured ? "Update Configuration" : "Save Configuration"
              enabled: opacUrlField.text !== "" && apiKeyField.text !== ""
              highlighted: true
              onClicked: {
                if (opacManager.isConfigured) {
                  if (opacManager.updateConfiguration(
                        opacUrlField.text,
                        apiKeyField.text,
                        syncIntervalSlider.value,
                        pickupDaysSpinBox.value,
                        expiryDaysSpinBox.value)) {
                    showSuccessMessage("Configuration updated successfully")
                  } else {
                    showErrorMessage("Failed to update configuration")
                  }
                } else {
                  if (opacManager.initializeConfiguration(
                        opacUrlField.text,
                        apiKeyField.text,
                        syncIntervalSlider.value,
                        pickupDaysSpinBox.value,
                        expiryDaysSpinBox.value)) {
                    showSuccessMessage("Configuration saved successfully. Initial sync started.")
                  } else {
                    showErrorMessage("Failed to save configuration")
                  }
                }
              }
            }
          }
        }
      }

      // Synchronization Settings Section
      GroupBox {
        Layout.fillWidth: true
        Layout.margins: 20
        title: "Sync Settings"

        ColumnLayout {
          width: parent.width
          spacing: 15

          // Auto-sync toggle
          RowLayout {
            Layout.fillWidth: true

            Label {
              text: "Enable Auto-sync:"
              Layout.fillWidth: true
            }

            Switch {
              id: autoSyncSwitch
              checked: opacManager.autoSyncEnabled
              enabled: opacManager.isConfigured
              onToggled: {
                opacManager.autoSyncEnabled = checked
              }
            }
          }

          // Sync interval
          Label {
            text: "Sync Interval: " + syncIntervalSlider.value + " minutes"
            font.bold: true
          }

          Slider {
            id: syncIntervalSlider
            Layout.fillWidth: true
            from: 15
            to: 1440
            stepSize: 15
            value: opacManager.syncIntervalMinutes
            enabled: opacManager.isConfigured
          }

          // Notification pickup days
          RowLayout {
            Layout.fillWidth: true

            Label {
              text: "Pickup Deadline (days):"
              Layout.fillWidth: true
            }

            SpinBox {
              id: pickupDaysSpinBox
              from: 1
              to: 7
              value: opacManager.isConfigured ? opacManager.getConfiguration()["notificationPickupDays"] : 3
              enabled: opacManager.isConfigured
            }
          }

          // Reservation expiry days
          RowLayout {
            Layout.fillWidth: true

            Label {
              text: "Reservation Expiry (days):"
              Layout.fillWidth: true
            }

            SpinBox {
              id: expiryDaysSpinBox
              from: 3
              to: 30
              value: opacManager.isConfigured ? opacManager.getConfiguration()["reservationExpiryDays"] : 7
              enabled: opacManager.isConfigured
            }
          }

          // Last sync time
          Label {
            text: "Last Sync: " + opacManager.lastSyncTime
            color: "gray"
          }
        }
      }

      // Manual Sync Controls Section
      GroupBox {
        Layout.fillWidth: true
        Layout.margins: 20
        title: "Manual Synchronization"

        ColumnLayout {
          width: parent.width
          spacing: 15

          // Sync status with color coding
          Rectangle {
            Layout.fillWidth: true
            height: statusLabel.height + 20
            color: {
              if (opacManager.isSyncing) return "#e3f2fd"
              if (opacManager.syncStatus.includes("success") ||
                  opacManager.syncStatus.includes("completed")) return "#e8f5e9"
              if (opacManager.syncStatus.includes("failed") ||
                  opacManager.syncStatus.includes("error")) return "#ffebee"
              return "#f5f5f5"
            }
            radius: 5

            Label {
              id: statusLabel
              anchors.centerIn: parent
              text: opacManager.syncStatus
              font.italic: true
              wrapMode: Text.WordWrap
              width: parent.width - 20
              horizontalAlignment: Text.AlignHCenter
            }
          }

          // Progress indicator
          ProgressBar {
            Layout.fillWidth: true
            indeterminate: true
            visible: opacManager.isSyncing
          }

          // Sync buttons
          GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            Button {
              text: "Sync Now (Full)"
              Layout.fillWidth: true
              enabled: opacManager.isConfigured && !opacManager.isSyncing
              onClicked: opacManager.syncNow()
            }

            Button {
              text: "Sync Books Only"
              Layout.fillWidth: true
              enabled: opacManager.isConfigured && !opacManager.isSyncing
              onClicked: opacManager.syncBooks()
            }

            Button {
              text: "Sync Users Only"
              Layout.fillWidth: true
              enabled: opacManager.isConfigured && !opacManager.isSyncing
              onClicked: opacManager.syncUsers()
            }

            Button {
              text: "Check Reservations"
              Layout.fillWidth: true
              enabled: opacManager.isConfigured && !opacManager.isSyncing
              onClicked: opacManager.syncReservations()
            }
          }

          Button {
            text: "View Sync History"
            Layout.fillWidth: true
            onClicked: syncHistoryDialog.open()
          }
        }
      }

      // Active Reservations Section
      GroupBox {
        Layout.fillWidth: true
        Layout.margins: 20
        title: "Active Reservations (" + opacManager.pendingReservationsCount + ")"

        ColumnLayout {
          width: parent.width
          spacing: 15

          // Filter buttons
          RowLayout {
            Layout.fillWidth: true

            ButtonGroup {
              id: filterButtonGroup
            }

            Button {
              text: "All"
              checkable: true
              checked: true
              ButtonGroup.group: filterButtonGroup
              onClicked: reservationsModel.filterStatus = "all"
            }

            Button {
              text: "Pending"
              checkable: true
              ButtonGroup.group: filterButtonGroup
              onClicked: reservationsModel.filterStatus = "pending"
            }

            Button {
              text: "Notified"
              checkable: true
              ButtonGroup.group: filterButtonGroup
              onClicked: reservationsModel.filterStatus = "notified"
            }

            Button {
              text: "Expired"
              checkable: true
              ButtonGroup.group: filterButtonGroup
              onClicked: reservationsModel.filterStatus = "expired"
            }

            Item { Layout.fillWidth: true }

            Button {
              text: "Refresh"
              icon.name: "view-refresh"
              onClicked: reservationsModel.refresh()
            }
          }

          // Reservations list
          ListView {
              boundsBehavior: Flickable.StopAtBounds
            id: reservationsListView
            Layout.fillWidth: true
            Layout.preferredHeight: 400
            clip: true

            ScrollBar.vertical: ScrollBar {
              id: vbar
              active: true
              policy: ScrollBar.AsNeeded
              width: 6
              parent: reservationsListView
              anchors.right: reservationsListView.right
              anchors.top: reservationsListView.top
              anchors.bottom: reservationsListView.bottom

              contentItem: Rectangle {
                implicitWidth: 6
                radius: width / 2
                color: vbar.pressed ? "#818181" : "#c2c2c2"
              }

              background: Rectangle {
                implicitWidth: 6
                radius: width / 2
                color: "#f0f0f0"
              }
            }

            model: ListModel {
              id: reservationsModel

              property string filterStatus: "all"

              function refresh() {
                clear()
                var reservations = opacManager.getReservationsList(filterStatus)
                for (var i = 0; i < reservations.length; i++) {
                  append(reservations[i])
                }
              }

              Component.onCompleted: refresh()
            }

            delegate: ItemDelegate {
              width: reservationsListView.width

              contentItem: ColumnLayout {
                spacing: 5

                RowLayout {
                  Layout.fillWidth: true

                  Label {
                    text: model.bookTitle
                    font.bold: true
                    Layout.fillWidth: true
                  }

                  Rectangle {
                    width: statusLabel1.width + 10
                    height: statusLabel1.height + 4
                    radius: 3
                    color: {
                      if (model.status === "pending") return "#FFF3CD"
                      if (model.status === "notified") return "#D1ECF1"
                      if (model.status === "expired") return "#F8D7DA"
                      return "#D4EDDA"
                    }

                    Label {
                      id: statusLabel1
                      anchors.centerIn: parent
                      text: model.status.toUpperCase()
                      font.pixelSize: 10
                      font.bold: true
                      color: {
                        if (model.status === "pending") return "#856404"
                        if (model.status === "notified") return "#0C5460"
                        if (model.status === "expired") return "#721C24"
                        return "#155724"
                      }
                    }
                  }
                }

                Label {
                  text: "Author: " + model.bookAuthor
                  color: "gray"
                }

                Label {
                  text: "User: " + model.userName + " (" + model.userEmail + ")"
                  color: "gray"
                }

                RowLayout {
                  Layout.fillWidth: true

                  Label {
                    text: "Reserved: " + Qt.formatDateTime(new Date(model.reservationDate), "yyyy-MM-dd hh:mm")
                    color: "gray"
                    font.pixelSize: 11
                  }

                  Label {
                    text: model.status === "notified"
                          ? "Pickup by: " + Qt.formatDateTime(new Date(model.pickupDeadline), "yyyy-MM-dd")
                          : "Expires: " + Qt.formatDateTime(new Date(model.expiryDate), "yyyy-MM-dd")
                    color: model.status === "notified" ? "#0C5460" : "gray"
                    font.pixelSize: 11
                    font.bold: model.status === "notified"
                  }

                  Item { Layout.fillWidth: true }
                }

                // Action buttons
                RowLayout {
                  Layout.fillWidth: true
                  spacing: 5

                  Button {
                    text: "View Details"
                    flat: true
                    font.pixelSize: 11
                    onClicked: showReservationDetails(model)
                  }

                  Button {
                    text: "Cancel"
                    flat: true
                    font.pixelSize: 11
                    visible: model.status === "pending" || model.status === "notified"
                    onClicked: confirmCancelDialog.show(model.reservationId)
                  }

                  Button {
                    text: "Issue Book"
                    flat: true
                    font.pixelSize: 11
                    highlighted: true
                    visible: model.status === "notified"
                    onClicked: {
                      // Navigate to book issue page with this reservation
                      // This would need to be implemented based on your app structure
                      console.log("Issue book for reservation:", model.reservationId)
                    }
                  }
                }
              }
            }

            // ScrollBar.vertical: ScrollBar {}

            Label {
              anchors.centerIn: parent
              text: "No reservations found"
              visible: reservationsListView.count === 0
              color: "gray"
            }
          }
        }
      }
    }
  }

  // Connection test result handler
  property string connectionStatusColor: "gray"

  Connections {
    target: opacManager

    function onConnectionTestResult(success, message) {
      connectionStatusText.text = message
      connectionStatusColor = success ? "#28a745" : "#dc3545"
    }

    function onSyncCompleted(message) {
      showSuccessMessage(message)
      reservationsModel.refresh()
    }

    function onSyncFailed(error) {
      showErrorMessage(error)
    }

    function onReservationsUpdated() {
      reservationsModel.refresh()
    }

    function onErrorOccurred(error) {
      showErrorMessage(error)
    }
  }

  // Success/Error messages
  function showSuccessMessage(message) {
    messageDialog.title = "Success"
    messageDialog.text = message
    messageDialog.standardButtons = Dialog.Ok
    messageDialog.open()
  }

  function showErrorMessage(message) {
    messageDialog.title = "Error"
    messageDialog.text = message
    messageDialog.standardButtons = Dialog.Ok
    messageDialog.open()
  }

  function showReservationDetails(reservation) {
    reservationDetailsDialog.showDetails(reservation)
  }

  // Message Dialog
  Dialog {
    id: messageDialog
    property alias text: messageLabel.text
    anchors.centerIn: parent
    modal: true
    standardButtons: Dialog.Ok

    Text {
      id: messageLabel
      color: "#8E8E8E"
      text: ""
    }
  }

  // Reservation Details Dialog
  Dialog {
    id: reservationDetailsDialog
    title: "Reservation Details"
    anchors.centerIn: parent
    modal: true
    standardButtons: Dialog.Close
    width: 500

    property var currentReservation: null

    function showDetails(reservation) {
      currentReservation = reservation
      open()
    }

    ColumnLayout {
      width: parent.width
      spacing: 10

      GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 10
        rowSpacing: 5

        Label { text: "Book Title:"; font.bold: true }
        Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.bookTitle : "" }

        Label { text: "Author:"; font.bold: true }
        Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.bookAuthor : "" }

        Label { text: "Call Number:"; font.bold: true }
        Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.callNumber : "" }

        Label { text: "User:"; font.bold: true }
        Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.userName : "" }

        Label { text: "Email:"; font.bold: true }
        Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.userEmail : "" }

        Label { text: "Status:"; font.bold: true }
        Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.status : "" }

        Label { text: "Reserved:"; font.bold: true }
        Label { text: reservationDetailsDialog.currentReservation ? Qt.formatDateTime(new Date(reservationDetailsDialog.currentReservation.reservationDate), "yyyy-MM-dd hh:mm") : "" }

        Label { text: "Expires:"; font.bold: true }
        Label { text: reservationDetailsDialog.currentReservation ? Qt.formatDateTime(new Date(reservationDetailsDialog.currentReservation.expiryDate), "yyyy-MM-dd") : "" }

        Label {
          text: "Pickup Deadline:";
          font.bold: true
          visible: reservationDetailsDialog.currentReservation && reservationDetailsDialog.currentReservation.status === "notified"
        }
        Label {
          text: reservationDetailsDialog.currentReservation && reservationDetailsDialog.currentReservation.pickupDeadline ?
                  Qt.formatDateTime(new Date(reservationDetailsDialog.currentReservation.pickupDeadline), "yyyy-MM-dd") : ""
          visible: reservationDetailsDialog.currentReservation && reservationDetailsDialog.currentReservation.status === "notified"
        }
      }

      Label {
        text: "Notes:"
        font.bold: true
        visible: reservationDetailsDialog.currentReservation && reservationDetailsDialog.currentReservation.notes
      }

      Label {
        Layout.fillWidth: true
        text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.notes : ""
        wrapMode: Text.WordWrap
        visible: reservationDetailsDialog.currentReservation && reservationDetailsDialog.currentReservation.notes
      }
    }
  }

  // Sync History Dialog
  Dialog {
    id: syncHistoryDialog
    title: "Sync History"
    anchors.centerIn: parent
    modal: true
    standardButtons: Dialog.Close
    width: 700
    height: 500

    ColumnLayout {
      anchors.fill: parent
      spacing: 10

      RowLayout {
        Layout.fillWidth: true

        Label {
          text: "Recent synchronization operations"
          Layout.fillWidth: true
        }

        Button {
          text: "Clear History"
          onClicked: confirmClearHistoryDialog.open()
        }
      }

      ListView {
          boundsBehavior: Flickable.StopAtBounds
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        model: ListModel {
          id: syncHistoryModel

          function refresh() {
            clear()
            var history = opacManager.getSyncHistory(50)
            for (var i = 0; i < history.length; i++) {
              append(history[i])
            }
          }

          Component.onCompleted: refresh()
        }

        delegate: ItemDelegate {
          width: parent.width

          contentItem: ColumnLayout {
            spacing: 3

            RowLayout {
              Layout.fillWidth: true

              Rectangle {
                width: 8
                height: 8
                radius: 4
                color: {
                  if (model.status === "success") return "#28a745"
                  if (model.status === "partial") return "#ffc107"
                  return "#dc3545"
                }
              }

              Label {
                text: model.syncType + " - " + model.direction
                font.bold: true
              }

              Label {
                text: "(" + model.recordsAffected + " records)"
                color: "gray"
              }

              Item { Layout.fillWidth: true }

              Label {
                text: Qt.formatDateTime(new Date(model.startedAt), "yyyy-MM-dd hh:mm:ss")
                color: "gray"
                font.pixelSize: 10
              }
            }

            Label {
              text: "Triggered by: " + model.triggeredBy
              color: "gray"
              font.pixelSize: 10
            }

            Label {
              text: "Error: " + model.errorMessage
              color: "#dc3545"
              font.pixelSize: 10
              visible: model.errorMessage !== ""
              wrapMode: Text.WordWrap
              Layout.fillWidth: true
            }
          }
        }

        ScrollBar.vertical: ScrollBar {}
      }
    }

    onOpened: syncHistoryModel.refresh()
  }

  // Confirm Cancel Reservation Dialog
  Dialog {
    id: confirmCancelDialog
    title: "Cancel Reservation"
    anchors.centerIn: parent
    modal: true
    standardButtons: Dialog.Yes | Dialog.No

    property int reservationId: -1

    function show(resId) {
      reservationId = resId
      open()
    }

    Label {
      text: "Are you sure you want to cancel this reservation?"
    }

    onAccepted: {
      if (opacManager.cancelReservation(reservationId)) {
        showSuccessMessage("Reservation cancelled successfully")
        reservationsModel.refresh()
      } else {
        showErrorMessage("Failed to cancel reservation")
      }
    }
  }

  // Confirm Clear History Dialog
  Dialog {
    id: confirmClearHistoryDialog
    title: "Clear Sync History"
    anchors.centerIn: parent
    modal: true
    standardButtons: Dialog.Yes | Dialog.No

    Label {
      text: "Are you sure you want to clear all sync history?"
    }

    onAccepted: {
      if (opacManager.clearSyncHistory()) {
        showSuccessMessage("Sync history cleared")
        syncHistoryModel.refresh()
      } else {
        showErrorMessage("Failed to clear sync history")
      }
    }
  }
}
