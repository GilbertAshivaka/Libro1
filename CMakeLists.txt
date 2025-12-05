cmake_minimum_required(VERSION 3.16)
project(Libro1 VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)



find_package(Qt6 6.4 REQUIRED COMPONENTS Quick)
find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Widgets Sql Concurrent)
find_package(Qt6 6.4 REQUIRED COMPONENTS QuickControls2 Multimedia Pdf WebEngineQuick WebView)


qt_standard_project_setup()
set(CMAKE_AUTOMOC ON)

# Add ZXing library
add_subdirectory(zxing-cpp)

qt_add_executable(appLibro1
    main.cpp
    appIcon.rc
)

qt_add_qml_module(appLibro1
    URI Libro1
    VERSION 1.0
    QML_FILES Main.qml
    QML_FILES Login.qml
    QML_FILES MainLogin.qml
    QML_FILES TestPage.qml
    RESOURCES assets/library.jpg
    RESOURCES assets/lock1.png assets/lock2.png
    RESOURCES assets/library1.jpg assets/library2.jpeg assets/library3.jpeg
    RESOURCES assets/user.png
    RESOURCES assets/libroIcon.ico
    RESOURCES buttonImages/icons8-add-user-group-man-man-skin-type-7-48.png buttonImages/icons8-delete-48.png buttonImages/icons8-folder-48.png buttonImages/icons8-info-48.png buttonImages/icons8-lock-48.png buttonImages/icons8-logout-48.png buttonImages/icons8-new-file-48.png buttonImages/icons8-open-document-48.png buttonImages/icons8-pencil-48.png buttonImages/icons8-redo-40.png buttonImages/icons8-save-48.png buttonImages/icons8-search-40.png buttonImages/icons8-undo-40.png buttonImages/icons8-user-group-female-skin-type-7-48.png buttonImages/icons8-wish-list-64.png
    RESOURCES assets/1_jWx9suY2k3Ifq4B8A_vz9g.jpeg
    RESOURCES assets/dotmenu.png
    RESOURCES assets/menu.png
    RESOURCES assets/group.png assets/group1.png
    RESOURCES assets/cancel.png
    RESOURCES assets/close.png
    RESOURCES assets/cross.png
    RESOURCES assets/plus.png
    RESOURCES assets/backArrow.png
    RESOURCES assets/info1.png
    RESOURCES assets/info.png
    RESOURCES assets/messagePop.wav
    RESOURCES assets/library2.jpeg assets/library3.jpeg
    RESOURCES assets/left.png assets/right.png
    QML_FILES ui/AdminLogin.qml ui/StaffLogin.qml ui/UserLogin.qml
    QML_FILES AddManyUsers.qml AddUser.qml CustomButton.qml CustomDropShadow.qml CustomTxtInput.qml DynamicBox.qml LeftButtons.qml TopButtons.qml
    QML_FILES Page1.qml
    QML_FILES Settings.qml
    QML_FILES BookSettings.qml
    RESOURCES assets/setting.png
    RESOURCES assets/cloud-storage.png
    RESOURCES assets/book.png
    RESOURCES assets/townhall.png
    RESOURCES assets/userSettings.png assets/userSettings1.png
    RESOURCES assets/library.png
    RESOURCES assets/exchange.png
    RESOURCES assets/report.png
    RESOURCES assets/privacy-policy.png
    RESOURCES assets/mail.png
    RESOURCES assets/content-management.png
    RESOURCES assets/edit-document.png
    RESOURCES assets/modular.png
    RESOURCES assets/intergration.png
    RESOURCES assets/info3.png
    RESOURCES assets/inventory.png
    RESOURCES assets/logout.png assets/send-mail.png assets/send-message.png
    RESOURCES assets/support-services.png
    QML_FILES AddBooks.qml
    QML_FILES CustomTextField.qml
    RESOURCES assets/stack-of-books.png
    RESOURCES assets/userImage.png assets/userImage2.jpg assets/userImage3.jpeg
    QML_FILES Page2.qml
    QML_FILES QuickTools.qml
    QML_FILES DynamicComponentLoader.js
    QML_FILES ComponentLoader.qml
    RESOURCES assets/libraryBooks.png
    RESOURCES assets/contract.png
    RESOURCES assets/message.png
    QML_FILES QuickTools1.qml
    RESOURCES assets/bookBackground3.png
    RESOURCES assets/bookBackground.png
    RESOURCES assets/book1.png
    RESOURCES assets/addFriend.png
    RESOURCES assets/addGroup.png
    RESOURCES assets/addGroup1.png assets/join.png
    RESOURCES assets/pending.png
    RESOURCES assets/checkMark.png
    RESOURCES assets/tickMark.png
    RESOURCES assets/quarterCircle.png
    RESOURCES assets/graduationHat.png
    RESOURCES assets/helpIcon.png assets/otherToolsIcon.png assets/question1.png assets/searchIcon.png
    QML_FILES Searchbox.qml
    RESOURCES assets/returnBook.png
    QML_FILES AllBooks.qml
    RESOURCES assets/deleteClosed.png assets/deleteOpen.png
    RESOURCES assets/delegateBook.png
    QML_FILES ReturnBook.qml
    QML_FILES ReturnBookNumberRect.qml
    RESOURCES assets/returnBookIcon.png
    QML_FILES IssueBookSearchList.qml
    RESOURCES assets/issueInfo.png assets/issueInfo1.png
    QML_FILES PendingApprovals.qml
    QML_FILES
    RESOURCES assets/checkmarkGreen.png assets/checkmarkWhite.png assets/crossRed.png assets/crossWhite.png
    RESOURCES assets/sort.png
    QML_FILES IssuedBooks.qml
    QML_FILES TextUtils.qml
    RESOURCES assets/check.png assets/square.png
    QML_FILES EmptyApprovedList.qml
    RESOURCES assets/planet.png
    QML_FILES StudentPage.qml
    RESOURCES assets/feedbackIcon.png assets/suggestionIcon.png
    QML_FILES HistoryPage.qml
    QML_FILES SuggestionForm.qml
    QML_FILES FeedbackForm.qml
    RESOURCES appIcon.rc
    QML_FILES StaffPage.qml
    RESOURCES DynamicComponents/icons/barGraph.png DynamicComponents/icons/facebook.png DynamicComponents/icons/twitter.png DynamicComponents/icons/youtube.png
    QML_FILES DynamicComponents/QuotesPage.qml DynamicComponents/SocialMediaPage.qml
    QML_FILES DynamicComponents/Stats.qml DynamicComponents/StatsGraph.qml
    QML_FILES DynamicComponents/Suggestions.qml DynamicComponents/UserTips.qml
    RESOURCES assets/leftArrow.png assets/rightArrow.png
    RESOURCES DynamicComponents/icons/facebook.svg DynamicComponents/icons/twitter.svg DynamicComponents/icons/youtube.svg
    RESOURCES DynamicComponents/icons/linkedin.svg
    QML_FILES ToolsContainerPage.qml
    QML_FILES ToolsPage.qml
    QML_FILES ToolsTemplate.qml
    RESOURCES assets/cloudBackuprestore.png assets/documentation.png assets/emailNotification.png assets/inventory2.png assets/logging.png assets/reports.png assets/storage.png
    RESOURCES assets/pdf.png
    QML_FILES SettingsPage.qml
    QML_FILES SettingsTemplate.qml
    RESOURCES assets/digitalContent.png
    RESOURCES assets/bookstore.png
    QML_FILES ReportsPage.qml
    QML_FILES ReportsOverview.qml
    QML_FILES ReportsOverviewContainer.qml
    RESOURCES assets/allBooks.png assets/allUsers.png assets/category.png assets/export.png assets/issuedBooks.png assets/lostBooks.png assets/overdueBooks.png assets/print.png assets/reportsIcon.png assets/returnedBooks.png
    QML_FILES ReportsBooks.qml
    QML_FILES ReportsBooksContainer.qml
    QML_FILES ReportsUsers.qml
    QML_FILES ReportsUsersContainer.qml
    QML_FILES ReportsActivity.qml
    QML_FILES ReportsActivityContainer.qml
    QML_FILES AllUsers.qml
    QML_FILES ImportBooks.qml
    SOURCES databasemanager.h databasemanager.cpp
    SOURCES usermanager.h usermanager.cpp
    SOURCES userimporter.h userimporter.cpp
    SOURCES bookmanager.h bookmanager.cpp
    SOURCES bookimporter.h bookimporter.cpp
    SOURCES allbookslist.h allbookslist.cpp
    SOURCES allbookslistmodel.h allbookslistmodel.cpp
    SOURCES alluserslist.h alluserslist.cpp
    SOURCES alluserslistmodel.h alluserslistmodel.cpp
    SOURCES categorylist.h categorylist.cpp
    RESOURCES assets/addNewBook.png assets/advancedSearch.png assets/allBooksList.png assets/leftChevron.png assets/openSettings.png assets/rightChevron.png
    SOURCES barcodewriter.h barcodewriter.cpp
    SOURCES barcodereader.h barcodereader.cpp
    QML_FILES BarcodeMain.qml
    QML_FILES BarcodeWriter.qml
    QML_FILES ReadBarcode.qml
    SOURCES issuebookslist.h issuebookslist.cpp
    SOURCES issuebookslistmodel.h issuebookslistmodel.cpp
    RESOURCES assets/barcodeScan.png
    RESOURCES assets/reload.png
    SOURCES issuedbookslist.h issuedbookslist.cpp
    SOURCES issuedbookslistmodel.h issuedbookslistmodel.cpp
    SOURCES singlebookreturn.h singlebookreturn.cpp
    QML_FILES InventoryTracking.qml
    SOURCES inventorymanager.h inventorymanager.cpp
    RESOURCES assets/bell.png assets/settings.png
    QML_FILES CustomButtonWithIcon.qml
    QML_FILES BackupPage.qml
    SOURCES backupmanager.h backupmanager.cpp
    QML_FILES BackupManager2.qml
    SOURCES activitylogs.h activitylogs.cpp
    QML_FILES ActivityLogs.qml
    QML_FILES PDFReaderScreen.qml
    QML_FILES PDFReaderScreen2.qml
    RESOURCES assets/genAI.png
    RESOURCES assets/copySymbol.png assets/openFolder.png assets/selection.png assets/zoomIn.png assets/zoomOut.png
    QML_FILES LibroAIPage.qml
    RESOURCES webPages/LibroAI.html
    QML_FILES BookshopScreen.qml
    SOURCES bookshopmanager.h bookshopmanager.cpp
    RESOURCES .gitignore
    SOURCES storagemanager.h storagemanager.cpp
    QML_FILES StorageManager.qml
    QML_FILES DigitalMaterials.qml
    RESOURCES assets/cloud.png assets/folder.png
    SOURCES digitalmaterialsmanager.h digitalmaterialsmanager.cpp
    SOURCES emailnotificationcontroller.h emailnotificationcontroller.cpp
    QML_FILES EmailNotifications.qml
    SOURCES opacmanager.h opacmanager.cpp
    QML_FILES OpacConfigurationView.qml
    RESOURCES assets/opac.png
    SOURCES reportsmanager.h reportsmanager.cpp
    QML_FILES Reports/ReportsMainPage.qml
    QML_FILES Reports/ChartContainer.qml Reports/DateRangePicker.qml Reports/ExportButton.qml Reports/FilterPanel.qml Reports/LoadingIndicator.qml Reports/StatCard.qml
    QML_FILES Reports/CirculationReportsPage.qml Reports/CollectionReportsPage.qml Reports/DigitalMaterialsPage.qml Reports/FinancialReportsPage.qml Reports/LostDamagedReportsPage.qml Reports/OverdueReportsPage.qml Reports/ReservationReportsPage.qml Reports/SystemPerformancePage.qml Reports/TrendsInsightsPage.qml Reports/UserEngagementPage.qml
    QML_FILES ScreenshotTest.qml
    QML_FILES Reports/ReportComponentsContainer.qml
    SOURCES settingsmanager.h settingsmanager.cpp
    QML_FILES Settings/SettingsCard.qml Settings/SettingsDoubleSpinBox.qml Settings/SettingsLabelField.qml Settings/SettingsPage.qml Settings/SettingsSpinBox.qml Settings/SettingsSwitch.qml Settings/SettingsTextArea.qml Settings/SettingsTextField.qml
    RESOURCES assets/booksSettingsIcon.png assets/settingsIcon.png
    RESOURCES assets/mailSettings.png assets/reservationsSettings.png assets/systemSettings.png
)

# Include directories for ZXing
target_include_directories(appLibro1 PRIVATE
    ${CMAKE_SOURCE_DIR}/zxing-cpp/core
)


# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appLibro1 PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appLibro1
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

#Command so that the app can recognise .rc file/language
if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    enable_language("RC")
    set (WIN32_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/windows/MyApp.rc)
endif()

#Setting the icon
if(WIN32)
    set(APP_ICON_RESOURCE_WINDOWS "${CMAKE_CURRENT_SOURCE_DIR}/appIcon.rc")
    set_target_properties(appLibro1 PROPERTIES
        WIN32_EXECUTABLE TRUE
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
    )
    add_custom_command(TARGET appLibro1 POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy "${APP_ICON_RESOURCE_WINDOWS}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/appLibro1.ico"
    )
endif()

target_link_libraries(appLibro1
    PRIVATE ZXing::ZXing
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Widgets
    PRIVATE Qt6::Sql
    PRIVATE Qt6::Concurrent
    PRIVATE Qt6::QuickControls2
    PRIVATE Qt6::Core
    PRIVATE Qt6::Gui
    PRIVATE Qt6::Qml
    PRIVATE Qt6::Multimedia
    PRIVATE Qt6::Pdf
    PRIVATE Qt6::WebEngineQuick
    PRIVATE Qt6::WebView
)


include(GNUInstallDirs)
install(TARGETS appLibro1
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
