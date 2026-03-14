#ifndef BARCODEWRITER_H
#define BARCODEWRITER_H

#include <QObject>
#include <QPainter>
#include <QFont>
#include <QFontMetrics>
#include <QDebug>
#include <QImage>
#include <QRegularExpression>
#include <QDir>
#include <QMutex>
#include <QMutexLocker>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
#include <QPdfWriter>
#include <QPageLayout>
#include <QCoreApplication>

#include "BarcodeFormat.h"
#include "BitMatrix.h"
#include "MultiFormatWriter.h"


// ============================================================
// ZXingQt::WriteBarcode — free function to generate a barcode QImage
// ============================================================
namespace ZXingQt {
inline QImage WriteBarcode(QStringView text, ZXing::BarcodeFormat format, bool includeText = true)
{
    using namespace ZXing;
    auto writer = MultiFormatWriter(format);
    auto matrix = writer.encode(text.toString().toStdString(), 300, 200);
    auto bitmap = ToMatrix<uint8_t>(matrix);
    QImage barcodeImage = QImage(bitmap.data(), bitmap.width(), bitmap.height(),
                                 bitmap.width(), QImage::Format::Format_Grayscale8).copy();

    if (includeText) {
        int textHeight = 30;
        QImage completeImage(barcodeImage.width(), barcodeImage.height() + textHeight,
                             QImage::Format_RGB32);
        completeImage.fill(Qt::white);

        QPainter painter(&completeImage);
        painter.drawImage(0, 0, barcodeImage);

        painter.setPen(Qt::black);
        QFont font("Arial", 10);
        painter.setFont(font);

        QFontMetrics metrics(font);
        int textWidth = metrics.horizontalAdvance(text.toString());
        int x = (completeImage.width() - textWidth) / 2;
        int y = barcodeImage.height() + textHeight - 10;

        painter.drawText(x, y, text.toString());
        painter.end();

        return completeImage;
    }

    return barcodeImage;
}
} // namespace ZXingQt


// ============================================================
// BarcodeWriter — Singleton QObject for barcode generation
// ============================================================

// Naming mode for saved barcode files
// UseBarcode  -> "BookTitle_barcodeText.png"
// UseCallNumber -> "BookTitle_callNumber.png"
enum class FileNamingMode { UseBarcode, UseCallNumber };

class BarcodeWriter : public QObject
{
    Q_OBJECT

    // — QML-bound properties —
    Q_PROPERTY(QString imageUrl       READ imageUrl       NOTIFY imageUrlChanged)
    Q_PROPERTY(QString outputFolder   READ outputFolder   WRITE setOutputFolder   NOTIFY outputFolderChanged)
    Q_PROPERTY(int     namingMode     READ namingMode     WRITE setNamingMode     NOTIFY namingModeChanged)
    Q_PROPERTY(int     bulkProgress   READ bulkProgress   NOTIFY bulkProgressChanged)
    Q_PROPERTY(int     bulkTotal      READ bulkTotal      NOTIFY bulkTotalChanged)
    Q_PROPERTY(bool    bulkRunning    READ bulkRunning    NOTIFY bulkRunningChanged)
    Q_PROPERTY(QString statusMessage  READ statusMessage  NOTIFY statusMessageChanged)

public:
    // ---- Singleton access ----
    static BarcodeWriter* instance();

    // ---- Property getters ----
    QString imageUrl()     const;
    QString outputFolder() const;
    int     namingMode()   const;
    int     bulkProgress() const;
    int     bulkTotal()    const;
    bool    bulkRunning()  const;
    QString statusMessage() const;

    // ---- Property setters ----
    void setOutputFolder(const QString &folder);
    void setNamingMode(int mode);

    // ---- Static helper — generate a barcode image (no file I/O, no DB) ----
    static QImage generateBarcodeImage(const QString &format, const QString &text,
                                       bool includeText = true);

public slots:
    // Generate a single barcode from raw text, save to outputFolder
    void writeAndSaveBarcode(const QString &format, const QString &text,
                             const QString &title = "", const QString &author = "",
                             bool includeText = true);

    // Lookup a book by callNumber, retrieve its barcode from DB, generate & save
    void generateFromCallNumber(const QString &callNumber);

    // Bulk generate barcodes for books added between two dates (DD-MM-YYYY)
    // Runs asynchronously via QtConcurrent::run
    void generateBulkBarcodes(const QString &fromDate, const QString &toDate,
                              bool alsoPdf);

    // Cancel a running bulk operation
    void cancelBulk();

    // Let QML ask the user for a folder (returns path via signal)
    void browseOutputFolder();

signals:
    void imageUrlChanged();
    void outputFolderChanged();
    void namingModeChanged();
    void bulkProgressChanged();
    void bulkTotalChanged();
    void bulkRunningChanged();
    void statusMessageChanged();

    void barcodeSaved(const QString &filePath);
    void bulkFinished(int count);
    void bulkError(const QString &error);
    void errorOccurred(const QString &error);
    void folderSelected(const QString &path);

private:
    explicit BarcodeWriter(QObject *parent = nullptr);

    // Setters for internal state (emit signals on the main thread)
    void setImageUrl(const QString &url);
    void setStatusMessage(const QString &msg);
    void setBulkProgress(int value);
    void setBulkTotal(int value);
    void setBulkRunning(bool running);

    // Build a safe filename from book metadata
    QString buildFileName(const QString &title, const QString &barcodeText,
                          const QString &callNumber) const;
    // Sanitise a string for use in file names
    static QString sanitise(const QString &input, int maxLen = 30);

    // Generate the PDF sheet from a list of barcode images
    static bool generatePdfSheet(const QString &pdfPath,
                                 const QList<QPair<QImage, QString>> &barcodes);

    // ---- Data members ----
    static BarcodeWriter* m_instance;
    static QMutex         m_mutex;

    QString m_imageUrl;
    QString m_outputFolder;
    int     m_namingMode   = 0;   // 0 = UseBarcode, 1 = UseCallNumber
    int     m_bulkProgress = 0;
    int     m_bulkTotal    = 0;
    bool    m_bulkRunning  = false;
    bool    m_bulkCancelled = false;
    QString m_statusMessage;
};

#endif // BARCODEWRITER_H
