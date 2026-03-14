#include "barcodewriter.h"
#include "databasemanager.h"

#include <QStandardPaths>
#include <QFileDialog>
#include <QDateTime>
#include <QPageSize>

// ── Static members ──────────────────────────────────────────
BarcodeWriter* BarcodeWriter::m_instance = nullptr;
QMutex         BarcodeWriter::m_mutex;


// ── Constructor (private) ───────────────────────────────────
BarcodeWriter::BarcodeWriter(QObject *parent)
    : QObject(parent)
{
    // Default output folder: user's Downloads/Barcodes
    m_outputFolder = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)
                     + "/Barcodes";
    QDir().mkpath(m_outputFolder);
}

// ── Singleton accessor ──────────────────────────────────────
BarcodeWriter* BarcodeWriter::instance()
{
    QMutexLocker locker(&m_mutex);
    if (!m_instance)
        m_instance = new BarcodeWriter(QCoreApplication::instance());
    return m_instance;
}


// ════════════════════════════════════════════════════════════
//  Property getters
// ════════════════════════════════════════════════════════════
QString BarcodeWriter::imageUrl()      const { return m_imageUrl; }
QString BarcodeWriter::outputFolder()  const { return m_outputFolder; }
int     BarcodeWriter::namingMode()    const { return m_namingMode; }
int     BarcodeWriter::bulkProgress()  const { return m_bulkProgress; }
int     BarcodeWriter::bulkTotal()     const { return m_bulkTotal; }
bool    BarcodeWriter::bulkRunning()   const { return m_bulkRunning; }
QString BarcodeWriter::statusMessage() const { return m_statusMessage; }


// ════════════════════════════════════════════════════════════
//  Property setters
// ════════════════════════════════════════════════════════════
void BarcodeWriter::setOutputFolder(const QString &folder)
{
    QString path = folder;
    // Strip file:/// prefix that QML FolderDialog may produce
    if (path.startsWith("file:///"))
        path = path.mid(8);

    if (path != m_outputFolder) {
        m_outputFolder = path;
        QDir().mkpath(m_outputFolder);
        emit outputFolderChanged();
    }
}

void BarcodeWriter::setNamingMode(int mode)
{
    if (mode != m_namingMode) {
        m_namingMode = mode;
        emit namingModeChanged();
    }
}

void BarcodeWriter::setImageUrl(const QString &url)
{
    if (url != m_imageUrl) {
        m_imageUrl = url;
        emit imageUrlChanged();
    }
}

void BarcodeWriter::setStatusMessage(const QString &msg)
{
    if (msg != m_statusMessage) {
        m_statusMessage = msg;
        emit statusMessageChanged();
    }
}

void BarcodeWriter::setBulkProgress(int value)
{
    if (value != m_bulkProgress) {
        m_bulkProgress = value;
        emit bulkProgressChanged();
    }
}

void BarcodeWriter::setBulkTotal(int value)
{
    if (value != m_bulkTotal) {
        m_bulkTotal = value;
        emit bulkTotalChanged();
    }
}

void BarcodeWriter::setBulkRunning(bool running)
{
    if (running != m_bulkRunning) {
        m_bulkRunning = running;
        emit bulkRunningChanged();
    }
}


// ════════════════════════════════════════════════════════════
//  Static helper — pure image generation (no side effects)
// ════════════════════════════════════════════════════════════
QImage BarcodeWriter::generateBarcodeImage(const QString &format, const QString &text,
                                           bool includeText)
{
    if (format.isEmpty() || text.isEmpty())
        return QImage();

    auto barcodeFormat = ZXing::BarcodeFormatFromString(format.toStdString());
    return ZXingQt::WriteBarcode(QStringView(text), barcodeFormat, includeText);
}


// ════════════════════════════════════════════════════════════
//  Filename helpers
// ════════════════════════════════════════════════════════════
QString BarcodeWriter::sanitise(const QString &input, int maxLen)
{
    return input.left(maxLen)
    .simplified()
        .replace(" ", "_")
        .replace(QRegularExpression("[\\\\/:*?\"<>|]"), "");
}

QString BarcodeWriter::buildFileName(const QString &title,
                                     const QString &barcodeText,
                                     const QString &callNumber) const
{
    QString identifier;

    // Always start with the book title when available
    if (!title.isEmpty())
        identifier = sanitise(title);

    // Append barcode text or callNumber based on naming mode
    QString suffix;
    if (m_namingMode == static_cast<int>(FileNamingMode::UseCallNumber) && !callNumber.isEmpty())
        suffix = sanitise(callNumber);
    else if (!barcodeText.isEmpty())
        suffix = sanitise(barcodeText);

    if (identifier.isEmpty())
        identifier = suffix.isEmpty() ? "barcode" : suffix;
    else if (!suffix.isEmpty())
        identifier += "_" + suffix;

    return identifier + ".png";
}


// ════════════════════════════════════════════════════════════
//  Single barcode — from raw text
// ════════════════════════════════════════════════════════════
void BarcodeWriter::writeAndSaveBarcode(const QString &format,
                                        const QString &text,
                                        const QString &title,
                                        const QString &author,
                                        bool includeText)
{
    if (format.isEmpty() || text.isEmpty()) {
        setStatusMessage("Cannot generate barcode from empty content.");
        emit errorOccurred("Cannot generate barcode from empty content.");
        return;
    }

    QImage result = generateBarcodeImage(format, text, includeText);
    if (result.isNull()) {
        setStatusMessage("Failed to generate barcode image.");
        emit errorOccurred("Failed to generate barcode image.");
        return;
    }

    // Build filename — use author in the title portion when title is provided
    QString displayTitle = title;
    if (!title.isEmpty() && !author.isEmpty()) {
        QString safeAuthor = sanitise(author.split(" ").last(), 15);
        displayTitle = sanitise(title) + "_" + safeAuthor;
    }

    QString fileName = buildFileName(displayTitle, text, "");
    QString filePath = m_outputFolder + "/" + fileName;

    if (!result.save(filePath, "PNG")) {
        setStatusMessage("Failed to save barcode to: " + filePath);
        emit errorOccurred("Failed to save barcode to: " + filePath);
        return;
    }

    setImageUrl("file:///" + filePath);
    setStatusMessage("Barcode saved: " + fileName);
    emit barcodeSaved(filePath);
}


// ════════════════════════════════════════════════════════════
//  Single barcode — lookup by callNumber
// ════════════════════════════════════════════════════════════
void BarcodeWriter::generateFromCallNumber(const QString &callNumber)
{
    if (callNumber.isEmpty()) {
        setStatusMessage("Call number is empty.");
        emit errorOccurred("Call number is empty.");
        return;
    }

    QSqlDatabase db = DatabaseManager::getConnection();
    if (!db.isOpen()) {
        setStatusMessage("Database connection not available.");
        emit errorOccurred("Database connection not available.");
        return;
    }

    QSqlQuery query(db);
    query.prepare("SELECT title, author, barcode, callNumber FROM books WHERE callNumber = ?");
    query.addBindValue(callNumber);

    if (!query.exec() || !query.next()) {
        setStatusMessage("No book found with call number: " + callNumber);
        emit errorOccurred("No book found with call number: " + callNumber);
        return;
    }

    QString title   = query.value("title").toString();
    QString author  = query.value("author").toString();
    QString barcode = query.value("barcode").toString();
    QString dbCallNumber = query.value("callNumber").toString();

    if (barcode.isEmpty()) {
        setStatusMessage("Book '" + title + "' has no barcode value in the database.");
        emit errorOccurred("Book has no barcode value.");
        return;
    }

    QImage result = generateBarcodeImage("Code128", barcode, true);
    if (result.isNull()) {
        setStatusMessage("Failed to generate barcode image.");
        emit errorOccurred("Failed to generate barcode image.");
        return;
    }

    QString fileName = buildFileName(title, barcode, dbCallNumber);
    QString filePath = m_outputFolder + "/" + fileName;

    if (!result.save(filePath, "PNG")) {
        setStatusMessage("Failed to save barcode to: " + filePath);
        emit errorOccurred("Failed to save: " + filePath);
        return;
    }

    setImageUrl("file:///" + filePath);
    setStatusMessage("Barcode saved: " + fileName);
    emit barcodeSaved(filePath);
}


// ════════════════════════════════════════════════════════════
//  Bulk generation (asynchronous)
// ════════════════════════════════════════════════════════════
void BarcodeWriter::generateBulkBarcodes(const QString &fromDate,
                                         const QString &toDate,
                                         bool alsoPdf)
{
    if (m_bulkRunning) {
        setStatusMessage("A bulk operation is already in progress.");
        return;
    }

    // Parse dates — expected format DD-MM-YYYY
    QDate from = QDate::fromString(fromDate, "dd-MM-yyyy");
    if (!from.isValid()) {
        setStatusMessage("Invalid 'From' date. Use DD-MM-YYYY format.");
        emit errorOccurred("Invalid 'From' date.");
        return;
    }

    QDate to;
    if (toDate.isEmpty())
        to = QDate::currentDate();
    else
        to = QDate::fromString(toDate, "dd-MM-yyyy");

    if (!to.isValid()) {
        setStatusMessage("Invalid 'To' date. Use DD-MM-YYYY format.");
        emit errorOccurred("Invalid 'To' date.");
        return;
    }

    // Convert to ISO for SQL comparison (SQLite stores dates as YYYY-MM-DD...)
    QString isoFrom = from.toString("yyyy-MM-dd");
    QString isoTo   = to.toString("yyyy-MM-dd") + " 23:59:59";

    // Capture values needed by the worker thread
    QString folder    = m_outputFolder;
    int     naming    = m_namingMode;

    m_bulkCancelled = false;
    setBulkRunning(true);
    setBulkProgress(0);
    setBulkTotal(0);
    setStatusMessage("Starting bulk barcode generation...");

    // ── Run in a background thread ──────────────────────────
    QtConcurrent::run([this, isoFrom, isoTo, folder, naming, alsoPdf]()
                      {
                          // Thread-local database connection
                          QString connName = "barcodeWriter_bulk_" +
                                             QString::number(reinterpret_cast<quintptr>(QThread::currentThread()));

                          {
                              QSqlDatabase threadDb;
                              if (QSqlDatabase::contains(connName)) {
                                  threadDb = QSqlDatabase::database(connName);
                              } else {
                                  threadDb = QSqlDatabase::addDatabase("QSQLITE", connName);
                                  // Reuse the same DB file as the main connection
                                  threadDb.setDatabaseName(DatabaseManager::getDatabasePath());
                              }

                              if (!threadDb.open()) {
                                  QMetaObject::invokeMethod(this, [this]() {
                                      setBulkRunning(false);
                                      setStatusMessage("Failed to open database for bulk operation.");
                                      emit bulkError("Database connection failed.");
                                  }, Qt::QueuedConnection);
                                  return;
                              }

                              QSqlQuery query(threadDb);
                              query.prepare("SELECT title, author, barcode, callNumber FROM books "
                                            "WHERE dateAdded >= ? AND dateAdded <= ? "
                                            "AND barcode IS NOT NULL AND barcode != '' "
                                            "ORDER BY dateAdded");
                              query.addBindValue(isoFrom);
                              query.addBindValue(isoTo);

                              if (!query.exec()) {
                                  QString err = query.lastError().text();
                                  QMetaObject::invokeMethod(this, [this, err]() {
                                      setBulkRunning(false);
                                      setStatusMessage("Query failed: " + err);
                                      emit bulkError(err);
                                  }, Qt::QueuedConnection);
                                  return;
                              }

                              // Collect all rows
                              struct BookRow {
                                  QString title, author, barcode, callNumber;
                              };
                              QVector<BookRow> rows;
                              while (query.next()) {
                                  rows.append({
                                      query.value("title").toString(),
                                      query.value("author").toString(),
                                      query.value("barcode").toString(),
                                      query.value("callNumber").toString()
                                  });
                              }

                              int total = rows.size();
                              QMetaObject::invokeMethod(this, [this, total]() {
                                  setBulkTotal(total);
                                  setStatusMessage(QString("Found %1 books. Generating barcodes...").arg(total));
                              }, Qt::QueuedConnection);

                              if (total == 0) {
                                  QMetaObject::invokeMethod(this, [this]() {
                                      setBulkRunning(false);
                                      setStatusMessage("No books found in the specified date range.");
                                      emit bulkFinished(0);
                                  }, Qt::QueuedConnection);
                                  return;
                              }

                              QDir().mkpath(folder);

                              // For PDF sheet collection
                              QList<QPair<QImage, QString>> pdfBarcodes;

                              int generated = 0;
                              for (int i = 0; i < total; ++i) {
                                  if (m_bulkCancelled) {
                                      QMetaObject::invokeMethod(this, [this, generated]() {
                                          setBulkRunning(false);
                                          setStatusMessage(QString("Bulk generation cancelled. %1 barcodes saved.").arg(generated));
                                          emit bulkFinished(generated);
                                      }, Qt::QueuedConnection);
                                      return;
                                  }

                                  const auto &row = rows[i];
                                  QImage img = generateBarcodeImage("Code128", row.barcode, true);
                                  if (img.isNull())
                                      continue;

                                  // Build filename using the captured naming mode
                                  QString fileName;
                                  QString safeName = sanitise(row.title);
                                  if (naming == static_cast<int>(FileNamingMode::UseCallNumber) && !row.callNumber.isEmpty())
                                      fileName = safeName + "_" + sanitise(row.callNumber) + ".png";
                                  else
                                      fileName = safeName + "_" + sanitise(row.barcode) + ".png";

                                  if (fileName.startsWith("_"))
                                      fileName = fileName.mid(1);

                                  QString filePath = folder + "/" + fileName;
                                  if (img.save(filePath, "PNG")) {
                                      ++generated;

                                      if (alsoPdf) {
                                          QString label = row.title;
                                          if (!row.callNumber.isEmpty())
                                              label += " (" + row.callNumber + ")";
                                          pdfBarcodes.append({img, label});
                                      }
                                  }

                                  // Update progress on main thread
                                  int prog = generated;
                                  QMetaObject::invokeMethod(this, [this, prog]() {
                                      setBulkProgress(prog);
                                  }, Qt::QueuedConnection);
                              }

                              // Generate PDF sheet if requested
                              bool pdfOk = true;
                              if (alsoPdf && !pdfBarcodes.isEmpty()) {
                                  QMetaObject::invokeMethod(this, [this]() {
                                      setStatusMessage("Generating PDF sheet...");
                                  }, Qt::QueuedConnection);

                                  QString pdfPath = folder + "/Barcodes_"
                                                    + QDate::currentDate().toString("yyyy-MM-dd") + ".pdf";
                                  pdfOk = generatePdfSheet(pdfPath, pdfBarcodes);
                              }

                              int finalCount = generated;
                              QMetaObject::invokeMethod(this, [this, finalCount, alsoPdf, pdfOk]() {
                                  setBulkRunning(false);
                                  setBulkProgress(finalCount);
                                  QString msg = QString("Done! %1 barcodes generated.").arg(finalCount);
                                  if (alsoPdf) {
                                      msg += pdfOk ? " PDF sheet saved." : " PDF generation failed.";
                                  }
                                  setStatusMessage(msg);
                                  emit bulkFinished(finalCount);
                              }, Qt::QueuedConnection);
                          }

                          // Clean up thread-local connection
                          QSqlDatabase::removeDatabase(connName);
                      });
}


// ════════════════════════════════════════════════════════════
//  Cancel bulk
// ════════════════════════════════════════════════════════════
void BarcodeWriter::cancelBulk()
{
    m_bulkCancelled = true;
    setStatusMessage("Cancelling...");
}


// ════════════════════════════════════════════════════════════
//  Browse for output folder (called from QML)
// ════════════════════════════════════════════════════════════
void BarcodeWriter::browseOutputFolder()
{
    QString dir = QFileDialog::getExistingDirectory(
        nullptr,
        "Select Output Folder",
        m_outputFolder,
        QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks);

    if (!dir.isEmpty()) {
        setOutputFolder(dir);
        emit folderSelected(dir);
    }
}


// ════════════════════════════════════════════════════════════
//  PDF sheet generation
// ════════════════════════════════════════════════════════════
bool BarcodeWriter::generatePdfSheet(const QString &pdfPath,
                                     const QList<QPair<QImage, QString>> &barcodes)
{
    if (barcodes.isEmpty())
        return false;

    // Layout configuration
    const int columns     = 3;
    const int barcodeW    = 190;   // points (~67 mm)
    const int barcodeH    = 90;    // points (~32 mm)
    const int labelH      = 18;
    const int cellW       = barcodeW + 10;
    const int cellH       = barcodeH + labelH + 15;
    const int marginLeft  = 30;
    const int marginTop   = 40;

    QPdfWriter writer(pdfPath);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setPageMargins(QMarginsF(0, 0, 0, 0));
    writer.setResolution(72);  // 1 point = 1 unit

    QPainter painter(&writer);
    if (!painter.isActive())
        return false;

    QFont titleFont("Arial", 14, QFont::Bold);
    QFont labelFont("Arial", 7);

    int pageW = writer.width();
    int row = 0, col = 0;
    bool firstPage = true;

    auto startPage = [&]() {
        if (!firstPage)
            writer.newPage();
        firstPage = false;
        row = 0;
        col = 0;

        // Page header
        painter.setFont(titleFont);
        painter.drawText(marginLeft, 25, "Library Barcode Sheet — "
                                             + QDate::currentDate().toString("dd MMM yyyy"));
    };

    startPage();

    for (int i = 0; i < barcodes.size(); ++i) {
        int x = marginLeft + col * cellW;
        int y = marginTop  + row * cellH;

        // Check if we need a new page
        if (y + cellH > writer.height() - 20) {
            startPage();
            x = marginLeft + col * cellW;
            y = marginTop  + row * cellH;
        }

        // Draw barcode image
        QRect imgRect(x, y, barcodeW, barcodeH);
        painter.drawImage(imgRect, barcodes[i].first);

        // Draw label
        painter.setFont(labelFont);
        QRect labelRect(x, y + barcodeH + 2, barcodeW, labelH);
        painter.drawText(labelRect, Qt::AlignHCenter | Qt::TextWordWrap,
                         barcodes[i].second);

        // Advance grid position
        ++col;
        if (col >= columns) {
            col = 0;
            ++row;
        }
    }

    painter.end();
    return true;
}
