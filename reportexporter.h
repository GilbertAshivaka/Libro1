#ifndef REPORTEXPORTER_H
#define REPORTEXPORTER_H

#include <QObject>
#include <QVariantMap>
#include <QString>

class QWebEnginePage;
class QPrinter;

/*
 * ReportExporter - Document generation & output engine for the Reports module.
 *
 * Takes a generic, filter-aware report payload built in QML (so the printout
 * matches exactly what is on screen, without re-querying the database) and
 * turns it into one of three outputs:
 *
 *   - PDF file            : HTML + Chart.js rendered off-screen -> printToPdf()
 *   - Physical printer    : the same PDF -> QPdfDocument -> QPainter -> QPrinter
 *   - CSV file            : tabular data written directly from the payload
 *
 * A single HTML generator feeds both PDF and physical printing; CSV bypasses
 * WebEngine entirely. Charts are re-rendered in-document with a bundled
 * (offline) copy of Chart.js.
 *
 * ----------------------------------------------------------------------------
 * Payload schema (QVariantMap):
 * {
 *   "title":       "Financial Reports",
 *   "subtitle":    "Monitor fines, losses, and financial metrics",   // optional
 *   "generatedAt": "...",                                            // optional, auto-filled
 *   "filters":  [ { "label": "Date Range", "value": "Current Month" }, ... ],
 *   "sections": [
 *     {
 *       "title": "Key Metrics",
 *       "kind":  "metrics",
 *       "data":  [ { "label": "Fines Generated", "value": "$0", "unit": "" }, ... ]
 *     },
 *     {
 *       "title":     "Fine Collection Over Time",
 *       "subtitle":  "Revenue from fines collected monthly",         // optional
 *       "kind":      "chart",
 *       "chartType": "line",          // line | bar | stackedBar | pie | doughnut
 *       "labels":    [ "Jan", "Feb", ... ],
 *       "datasets":  [ { "label": "Collected", "color": "#4CAF50", "data": [..] } ],
 *       "table":     { "headers": [..], "rows": [[..], ..] }          // optional, for CSV
 *     },
 *     {
 *       "title": "...",
 *       "kind":  "table",
 *       "table": { "headers": [..], "rows": [[..], ..] }
 *     }
 *   ]
 * }
 * ----------------------------------------------------------------------------
 */
class ReportExporter : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool isBusy READ isBusy NOTIFY isBusyChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit ReportExporter(QObject *parent = nullptr);
    ~ReportExporter();

    bool isBusy() const { return m_isBusy; }
    QString lastError() const { return m_lastError; }

    // ------------------------------------------------------------------
    // QML entry points
    // ------------------------------------------------------------------

    // Render the payload to a PDF file. If filePath is empty a native
    // "Save As" dialog is shown. Asynchronous: emits exportFinished().
    Q_INVOKABLE void exportToPdf(const QVariantMap &payload, const QString &filePath = QString());

    // Render the payload and send it to a physical printer. Shows the native
    // print dialog. Asynchronous: emits exportFinished().
    Q_INVOKABLE void printReport(const QVariantMap &payload);

    // Write the payload's tabular data to a CSV file. If filePath is empty a
    // native "Save As" dialog is shown. Synchronous: emits exportFinished().
    Q_INVOKABLE void exportToCsv(const QVariantMap &payload, const QString &filePath = QString());

    // Render a ready-made HTML document (e.g. a clearance receipt) to a PDF
    // file using the same off-screen WebEngine pipeline. If filePath is empty a
    // native "Save As" dialog is shown. Asynchronous: emits exportFinished().
    Q_INVOKABLE void exportHtmlToPdf(const QString &html, const QString &filePath = QString(),
                                     const QString &suggestedName = QString());

signals:
    void isBusyChanged();
    void lastErrorChanged();

    // success == true  -> outputPath holds the produced file (empty for print)
    // success == false -> message holds the error
    void exportFinished(bool success, const QString &outputPath, const QString &message);

private:
    enum class PendingOp { None, Pdf, Print };

    // HTML document generation
    QString buildHtml(const QVariantMap &payload) const;
    QString buildSectionHtml(const QVariantMap &section, int chartIndex) const;
    static QString chartJsSource();             // bundled Chart.js, read once & cached
    static QString escapeHtml(const QString &text);
    static QString escapeCsvField(const QString &field);

    // WebEngine plumbing
    void ensurePage();
    void renderPdf(const QVariantMap &payload);           // shared by Pdf & Print
    void onPdfReady(const QString &pdfPath, bool success);
    void sendPdfToPrinter(const QString &pdfPath);        // QPdfDocument -> QPrinter

    // state helpers
    void setBusy(bool busy);
    void setError(const QString &error);
    void finish(bool success, const QString &outputPath, const QString &message);

    bool m_isBusy = false;
    QString m_lastError;

    QWebEnginePage *m_page = nullptr;
    QPrinter *m_printer = nullptr;       // alive across the async print render
    PendingOp m_pendingOp = PendingOp::None;
    bool m_awaitingRender = false;
    QString m_targetPdfPath;             // where printToPdf writes for the current op
    bool m_targetIsTemp = false;         // delete m_targetPdfPath after use (print)
};

#endif // REPORTEXPORTER_H
