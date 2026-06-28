/*
 * ReportExporter - see reportexporter.h for the payload schema and design notes.
 *
 * Output pipeline:
 *   payload --> buildHtml() --> QWebEnginePage (off-screen) --> printToPdf()
 *      PDF  : printToPdf() writes straight to the chosen file
 *      Print: printToPdf() writes a temp file -> QPdfDocument -> QPainter -> QPrinter
 *      CSV  : written directly from the payload, bypassing WebEngine
 */

#include "reportexporter.h"

#include <QWebEnginePage>
#include <QWebEngineProfile>

#include <QPrinter>
#include <QPrintDialog>

#include <QPdfDocument>

#include <QPainter>
#include <QImage>

#include <QFile>
#include <QFileDialog>
#include <QStandardPaths>
#include <QDir>
#include <QTextStream>

#include <QPageLayout>
#include <QPageSize>
#include <QMarginsF>

#include <QDateTime>
#include <QTimer>
#include <QDebug>

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

// ============================================================================
// Construction
// ============================================================================

ReportExporter::ReportExporter(QObject *parent)
    : QObject(parent)
{
}

ReportExporter::~ReportExporter()
{
    if (m_printer) {
        delete m_printer;
        m_printer = nullptr;
    }
    // m_page is parented to this, deleted automatically.
}

// ============================================================================
// State helpers
// ============================================================================

void ReportExporter::setBusy(bool busy)
{
    if (m_isBusy == busy)
        return;
    m_isBusy = busy;
    emit isBusyChanged();
}

void ReportExporter::setError(const QString &error)
{
    if (m_lastError == error)
        return;
    m_lastError = error;
    emit lastErrorChanged();
}

void ReportExporter::finish(bool success, const QString &outputPath, const QString &message)
{
    if (!success) {
        setError(message);
        qWarning() << "[ReportExporter] export failed:" << message;
    }

    m_pendingOp = PendingOp::None;
    m_awaitingRender = false;

    if (m_targetIsTemp && !m_targetPdfPath.isEmpty())
        QFile::remove(m_targetPdfPath);
    m_targetPdfPath.clear();
    m_targetIsTemp = false;

    if (m_printer) {
        delete m_printer;
        m_printer = nullptr;
    }

    setBusy(false);
    emit exportFinished(success, outputPath, message);
}

// ============================================================================
// WebEngine page setup
// ============================================================================

void ReportExporter::ensurePage()
{
    if (m_page)
        return;

    // Off-screen page on the default profile; no view required for printToPdf.
    m_page = new QWebEnginePage(QWebEngineProfile::defaultProfile(), this);

    connect(m_page, &QWebEnginePage::loadFinished, this, [this](bool ok) {
        if (!m_awaitingRender)
            return;

        if (!ok) {
            finish(false, QString(), QStringLiteral("Failed to render the report document."));
            return;
        }

        // Charts are built synchronously with animations disabled, so the
        // canvases are drawn by the time loadFinished fires. A short settle
        // delay guards against layout/paint races before we snapshot to PDF.
        QTimer::singleShot(200, this, [this]() {
            if (!m_awaitingRender || !m_page)
                return;
            m_awaitingRender = false;

            QPageLayout layout = m_printer
                ? m_printer->pageLayout()
                : QPageLayout(QPageSize(QPageSize::A4), QPageLayout::Portrait,
                              QMarginsF(12, 12, 12, 12), QPageLayout::Millimeter);

            m_page->printToPdf(m_targetPdfPath, layout);
        });
    });

    connect(m_page, &QWebEnginePage::pdfPrintingFinished, this,
            [this](const QString &filePath, bool success) {
        onPdfReady(filePath, success);
    });
}

void ReportExporter::renderPdf(const QVariantMap &payload)
{
    ensurePage();

    const QString html = buildHtml(payload);

    m_awaitingRender = true;
    // baseUrl left empty: Chart.js is inlined into the document, so no external
    // resources need resolving (works fully offline).
    m_page->setHtml(html);
}

void ReportExporter::onPdfReady(const QString &filePath, bool success)
{
    Q_UNUSED(filePath)

    if (m_pendingOp == PendingOp::None)
        return;

    if (!success) {
        finish(false, QString(), QStringLiteral("Failed to generate the PDF document."));
        return;
    }

    if (m_pendingOp == PendingOp::Pdf) {
        const QString out = m_targetPdfPath;
        finish(true, out, QString());
    } else if (m_pendingOp == PendingOp::Print) {
        sendPdfToPrinter(m_targetPdfPath);
    }
}

// ============================================================================
// PDF export
// ============================================================================

void ReportExporter::exportToPdf(const QVariantMap &payload, const QString &filePath)
{
    if (m_isBusy) {
        emit exportFinished(false, QString(), QStringLiteral("Another export is already in progress."));
        return;
    }

    QString path = filePath;
    if (path.isEmpty()) {
        const QString suggested = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                                  + QDir::separator()
                                  + payload.value("title", "report").toString().simplified().replace(' ', '_')
                                  + ".pdf";
        path = QFileDialog::getSaveFileName(nullptr, QStringLiteral("Export Report as PDF"),
                                            suggested, QStringLiteral("PDF Documents (*.pdf)"));
    }
    if (path.isEmpty()) {
        emit exportFinished(false, QString(), QString());   // user cancelled, no error
        return;
    }
    if (!path.endsWith(".pdf", Qt::CaseInsensitive))
        path += ".pdf";

    setBusy(true);
    setError(QString());
    m_pendingOp = PendingOp::Pdf;
    m_targetPdfPath = path;
    m_targetIsTemp = false;

    renderPdf(payload);
}

void ReportExporter::exportHtmlToPdf(const QString &html, const QString &filePath,
                                     const QString &suggestedName)
{
    if (m_isBusy) {
        emit exportFinished(false, QString(), QStringLiteral("Another export is already in progress."));
        return;
    }

    QString path = filePath;
    if (path.isEmpty()) {
        QString base = suggestedName.isEmpty() ? QStringLiteral("receipt")
                                               : suggestedName.simplified().replace(' ', '_');
        const QString suggested = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                                  + QDir::separator() + base + ".pdf";
        path = QFileDialog::getSaveFileName(nullptr, QStringLiteral("Export as PDF"),
                                            suggested, QStringLiteral("PDF Documents (*.pdf)"));
    }
    if (path.isEmpty()) {
        emit exportFinished(false, QString(), QString());   // user cancelled
        return;
    }
    if (!path.endsWith(".pdf", Qt::CaseInsensitive))
        path += ".pdf";

    setBusy(true);
    setError(QString());
    m_pendingOp = PendingOp::Pdf;
    m_targetPdfPath = path;
    m_targetIsTemp = false;

    // Render the supplied HTML directly (no payload / Chart.js needed).
    ensurePage();
    m_awaitingRender = true;
    m_page->setHtml(html);
}

// ============================================================================
// Physical printing
// ============================================================================

void ReportExporter::printReport(const QVariantMap &payload)
{
    if (m_isBusy) {
        emit exportFinished(false, QString(), QStringLiteral("Another export is already in progress."));
        return;
    }

    // Ask the user for the printer & page setup up front, so the PDF we render
    // matches the chosen page size exactly.
    m_printer = new QPrinter(QPrinter::HighResolution);
    QPrintDialog dialog(m_printer, nullptr);
    dialog.setWindowTitle(QStringLiteral("Print Report"));

    if (dialog.exec() != QDialog::Accepted) {
        delete m_printer;
        m_printer = nullptr;
        emit exportFinished(false, QString(), QString());   // user cancelled
        return;
    }

    setBusy(true);
    setError(QString());
    m_pendingOp = PendingOp::Print;

    // Render to a temp PDF first; it is sent to the printer once ready.
    m_targetPdfPath = QDir::temp().filePath(
        QStringLiteral("libro_report_%1.pdf").arg(QDateTime::currentMSecsSinceEpoch()));
    m_targetIsTemp = true;

    renderPdf(payload);
}

void ReportExporter::sendPdfToPrinter(const QString &pdfPath)
{
    if (!m_printer) {
        finish(false, QString(), QStringLiteral("Printer was not initialised."));
        return;
    }

    QPdfDocument doc;
    if (doc.load(pdfPath) != QPdfDocument::Error::None) {
        finish(false, QString(), QStringLiteral("Could not open the rendered document for printing."));
        return;
    }

    QPainter painter;
    if (!painter.begin(m_printer)) {
        finish(false, QString(), QStringLiteral("Could not start the print job."));
        return;
    }

    const int dpi = m_printer->resolution();
    const QRectF targetRect = m_printer->pageRect(QPrinter::DevicePixel);

    for (int i = 0; i < doc.pageCount(); ++i) {
        if (i > 0)
            m_printer->newPage();

        // Render the PDF page to an image at the printer's resolution.
        const QSizeF pagePt = doc.pagePointSize(i);             // 1/72 inch units
        const QSize imageSize(qRound(pagePt.width()  / 72.0 * dpi),
                              qRound(pagePt.height() / 72.0 * dpi));

        const QImage image = doc.render(i, imageSize);
        if (image.isNull())
            continue;

        // Scale the page image to fit the printable area, preserving aspect.
        QSizeF scaled = image.size().scaled(targetRect.size().toSize(), Qt::KeepAspectRatio);
        QRectF drawRect(targetRect.topLeft(), scaled);
        drawRect.moveCenter(targetRect.center());

        painter.drawImage(drawRect, image);
    }

    painter.end();
    finish(true, QString(), QString());
}

// ============================================================================
// CSV export
// ============================================================================

void ReportExporter::exportToCsv(const QVariantMap &payload, const QString &filePath)
{
    if (m_isBusy) {
        emit exportFinished(false, QString(), QStringLiteral("Another export is already in progress."));
        return;
    }

    QString path = filePath;
    if (path.isEmpty()) {
        const QString suggested = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                                  + QDir::separator()
                                  + payload.value("title", "report").toString().simplified().replace(' ', '_')
                                  + ".csv";
        path = QFileDialog::getSaveFileName(nullptr, QStringLiteral("Export Report as CSV"),
                                            suggested, QStringLiteral("CSV Files (*.csv)"));
    }
    if (path.isEmpty()) {
        emit exportFinished(false, QString(), QString());
        return;
    }
    if (!path.endsWith(".csv", Qt::CaseInsensitive))
        path += ".csv";

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit exportFinished(false, QString(), QStringLiteral("Could not open the file for writing."));
        return;
    }

    QTextStream out(&file);
    out.setEncoding(QStringConverter::Utf8);
    out << "\xEF\xBB\xBF";   // UTF-8 BOM so Excel detects encoding

    // Document header
    out << escapeCsvField(payload.value("title").toString()) << "\n";
    if (payload.contains("subtitle"))
        out << escapeCsvField(payload.value("subtitle").toString()) << "\n";
    out << escapeCsvField(QStringLiteral("Generated"))
        << "," << escapeCsvField(QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm")) << "\n";

    const QVariantList filters = payload.value("filters").toList();
    for (const QVariant &f : filters) {
        const QVariantMap fm = f.toMap();
        out << escapeCsvField(fm.value("label").toString())
            << "," << escapeCsvField(fm.value("value").toString()) << "\n";
    }
    out << "\n";

    // Sections
    const QVariantList sections = payload.value("sections").toList();
    for (const QVariant &s : sections) {
        const QVariantMap section = s.toMap();
        const QString kind = section.value("kind").toString();

        out << escapeCsvField(section.value("title").toString()) << "\n";

        if (kind == "metrics") {
            const QVariantList items = section.value("data").toList();
            for (const QVariant &it : items) {
                const QVariantMap m = it.toMap();
                QString value = m.value("value").toString();
                const QString unit = m.value("unit").toString();
                if (!unit.isEmpty())
                    value += " " + unit;
                out << escapeCsvField(m.value("label").toString())
                    << "," << escapeCsvField(value) << "\n";
            }
        } else {
            // chart or table: prefer an explicit table, else synthesise one
            // from chart labels + datasets.
            QVariantMap table = section.value("table").toMap();
            if (table.isEmpty() && kind == "chart") {
                QStringList headers;
                headers << "Label";
                const QVariantList datasets = section.value("datasets").toList();
                for (const QVariant &d : datasets)
                    headers << d.toMap().value("label").toString();

                QVariantList rows;
                const QVariantList labels = section.value("labels").toList();
                for (int r = 0; r < labels.size(); ++r) {
                    QVariantList row;
                    row << labels.at(r);
                    for (const QVariant &d : datasets) {
                        const QVariantList dData = d.toMap().value("data").toList();
                        row << (r < dData.size() ? dData.at(r) : QVariant());
                    }
                    rows << QVariant(row);
                }
                table.insert("headers", headers);
                table.insert("rows", rows);
            }

            const QVariantList headers = table.value("headers").toList();
            if (!headers.isEmpty()) {
                QStringList h;
                for (const QVariant &c : headers)
                    h << escapeCsvField(c.toString());
                out << h.join(',') << "\n";
            }
            const QVariantList rows = table.value("rows").toList();
            for (const QVariant &r : rows) {
                QStringList cells;
                for (const QVariant &c : r.toList())
                    cells << escapeCsvField(c.toString());
                out << cells.join(',') << "\n";
            }
        }
        out << "\n";
    }

    file.close();
    emit exportFinished(true, path, QString());
}

// ============================================================================
// CSV / HTML escaping helpers
// ============================================================================

QString ReportExporter::escapeCsvField(const QString &field)
{
    QString f = field;
    if (f.contains(',') || f.contains('"') || f.contains('\n') || f.contains('\r')) {
        f.replace('"', "\"\"");
        return '"' + f + '"';
    }
    return f;
}

QString ReportExporter::escapeHtml(const QString &text)
{
    QString t = text;
    t.replace('&', "&amp;");
    t.replace('<', "&lt;");
    t.replace('>', "&gt;");
    t.replace('"', "&quot;");
    return t;
}

// ============================================================================
// HTML document generation
// ============================================================================

QString ReportExporter::chartJsSource()
{
    static QString cached;
    if (!cached.isEmpty())
        return cached;

    QFile file(QStringLiteral(":/resources/chartjs/chart.umd.js"));
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        cached = QString::fromUtf8(file.readAll());
        file.close();
    } else {
        qWarning() << "[ReportExporter] bundled Chart.js resource not found;"
                      " charts will not render.";
        cached = QStringLiteral("/* Chart.js missing */");
    }
    return cached;
}

// Default palette for pie/doughnut slices when no per-point colours are given.
static QStringList defaultPalette()
{
    return { "#4CAF50", "#2196F3", "#FF9800", "#F44336", "#9C27B0",
             "#00BCD4", "#FFEB3B", "#795548", "#607D8B", "#E91E63" };
}

// Build a Chart.js config object for a chart section.
static QJsonObject buildChartConfig(const QVariantMap &section)
{
    const QString type = section.value("chartType", "bar").toString();
    const bool isPie = (type == "pie" || type == "doughnut");
    const bool isStacked = (type == "stackedBar");
    const bool isHorizontal = (type == "horizontalBar");
    const QString chartJsType = (isStacked || isHorizontal) ? "bar" : type;

    QJsonArray labels;
    for (const QVariant &l : section.value("labels").toList())
        labels.append(QJsonValue::fromVariant(l));

    QJsonArray datasets;
    const QVariantList srcDatasets = section.value("datasets").toList();
    const QStringList palette = defaultPalette();

    for (int di = 0; di < srcDatasets.size(); ++di) {
        const QVariantMap ds = srcDatasets.at(di).toMap();
        QJsonObject dataset;
        dataset.insert("label", ds.value("label").toString());

        QJsonArray data;
        for (const QVariant &v : ds.value("data").toList())
            data.append(QJsonValue::fromVariant(v));
        dataset.insert("data", data);

        const QString color = ds.value("color", palette.at(di % palette.size())).toString();

        if (isPie) {
            // One colour per slice: use supplied "colors" or fall back to palette.
            QJsonArray bg;
            const QVariantList colors = ds.value("colors").toList();
            for (int i = 0; i < labels.size(); ++i) {
                bg.append(i < colors.size() ? colors.at(i).toString()
                                            : palette.at(i % palette.size()));
            }
            dataset.insert("backgroundColor", bg);
        } else if (chartJsType == "line") {
            dataset.insert("borderColor", color);
            dataset.insert("backgroundColor", color);
            dataset.insert("fill", false);
            dataset.insert("tension", 0.3);
        } else {
            dataset.insert("backgroundColor", color);
        }
        datasets.append(dataset);
    }

    QJsonObject data;
    data.insert("labels", labels);
    data.insert("datasets", datasets);

    // Options: disable animation so the canvas is fully painted synchronously.
    QJsonObject options;
    options.insert("responsive", false);
    options.insert("animation", false);
    QJsonObject plugins;
    QJsonObject legend;
    legend.insert("display", datasets.size() > 1 || isPie);
    plugins.insert("legend", legend);
    options.insert("plugins", plugins);

    if (isStacked) {
        QJsonObject scales, x, y;
        x.insert("stacked", true);
        y.insert("stacked", true);
        scales.insert("x", x);
        scales.insert("y", y);
        options.insert("scales", scales);
    }
    if (isHorizontal)
        options.insert("indexAxis", "y");

    QJsonObject config;
    config.insert("type", chartJsType);
    config.insert("data", data);
    config.insert("options", options);
    return config;
}

QString ReportExporter::buildSectionHtml(const QVariantMap &section, int chartIndex) const
{
    const QString kind = section.value("kind").toString();
    QString html;

    html += "<section class=\"report-section\">";
    html += "<h2>" + escapeHtml(section.value("title").toString()) + "</h2>";
    if (section.contains("subtitle"))
        html += "<p class=\"section-subtitle\">"
                + escapeHtml(section.value("subtitle").toString()) + "</p>";

    if (kind == "metrics") {
        html += "<div class=\"metrics-grid\">";
        const QVariantList items = section.value("data").toList();
        for (const QVariant &it : items) {
            const QVariantMap m = it.toMap();
            QString value = escapeHtml(m.value("value").toString());
            const QString unit = m.value("unit").toString();
            if (!unit.isEmpty())
                value += " " + escapeHtml(unit);
            html += "<div class=\"metric-card\">"
                    "<div class=\"metric-value\">" + value + "</div>"
                    "<div class=\"metric-label\">" + escapeHtml(m.value("label").toString()) + "</div>"
                    "</div>";
        }
        html += "</div>";
    } else if (kind == "chart") {
        // Fixed-size canvas for crisp, deterministic rendering.
        html += "<div class=\"chart-wrap\">";
        html += QStringLiteral("<canvas id=\"chart%1\" width=\"680\" height=\"320\"></canvas>")
                    .arg(chartIndex);
        html += "</div>";
    } else if (kind == "table") {
        const QVariantMap table = section.value("table").toMap();
        const QVariantList headers = table.value("headers").toList();
        const QVariantList rows = table.value("rows").toList();

        html += "<table class=\"data-table\"><thead><tr>";
        for (const QVariant &h : headers)
            html += "<th>" + escapeHtml(h.toString()) + "</th>";
        html += "</tr></thead><tbody>";
        for (const QVariant &r : rows) {
            html += "<tr>";
            for (const QVariant &c : r.toList())
                html += "<td>" + escapeHtml(c.toString()) + "</td>";
            html += "</tr>";
        }
        html += "</tbody></table>";
    }

    html += "</section>";
    return html;
}

QString ReportExporter::buildHtml(const QVariantMap &payload) const
{
    const QString title = escapeHtml(payload.value("title", "Report").toString());
    const QString subtitle = escapeHtml(payload.value("subtitle").toString());
    const QString generatedAt = payload.value("generatedAt").toString().isEmpty()
        ? QDateTime::currentDateTime().toString("dddd, dd MMMM yyyy  HH:mm")
        : escapeHtml(payload.value("generatedAt").toString());

    // ---- body sections + collect chart configs -------------------------
    QString body;
    QJsonArray chartConfigs;     // [{ canvasId, config }]
    int chartIndex = 0;

    const QVariantList sections = payload.value("sections").toList();
    for (const QVariant &s : sections) {
        const QVariantMap section = s.toMap();
        const bool isChart = section.value("kind").toString() == "chart";

        body += buildSectionHtml(section, chartIndex);

        if (isChart) {
            QJsonObject entry;
            entry.insert("canvasId", QStringLiteral("chart%1").arg(chartIndex));
            entry.insert("config", buildChartConfig(section));
            chartConfigs.append(entry);
            ++chartIndex;
        }
    }

    // ---- filters chips --------------------------------------------------
    QString filtersHtml;
    const QVariantList filters = payload.value("filters").toList();
    if (!filters.isEmpty()) {
        filtersHtml += "<div class=\"filters\">";
        for (const QVariant &f : filters) {
            const QVariantMap fm = f.toMap();
            filtersHtml += "<span class=\"filter-chip\"><b>"
                         + escapeHtml(fm.value("label").toString()) + ":</b> "
                         + escapeHtml(fm.value("value").toString()) + "</span>";
        }
        filtersHtml += "</div>";
    }

    const QString configsJson =
        QString::fromUtf8(QJsonDocument(chartConfigs).toJson(QJsonDocument::Compact));

    // ---- assemble document ---------------------------------------------
    QString html;
    html += "<!DOCTYPE html><html><head><meta charset=\"utf-8\">";
    html += "<style>";
    html += R"CSS(
        * { box-sizing: border-box; }
        body { font-family: 'Segoe UI', Arial, sans-serif; color: #212121;
               margin: 0; padding: 0; font-size: 12px; }
        .page-header { border-bottom: 3px solid #4CAF50; padding-bottom: 10px;
                       margin-bottom: 16px; }
        .page-header h1 { margin: 0 0 4px 0; font-size: 22px; color: #1B5E20; }
        .page-header .subtitle { color: #555; font-size: 13px; }
        .page-header .generated { color: #888; font-size: 11px; margin-top: 6px; }
        .filters { margin-top: 8px; }
        .filter-chip { display: inline-block; background: #F1F8E9; color: #33691E;
                       border: 1px solid #C5E1A5; border-radius: 12px;
                       padding: 2px 10px; margin: 2px 4px 2px 0; font-size: 11px; }
        .report-section { margin-bottom: 22px; page-break-inside: avoid; }
        .report-section h2 { font-size: 15px; color: #2E7D32; margin: 0 0 4px 0;
                             border-left: 4px solid #4CAF50; padding-left: 8px; }
        .section-subtitle { color: #777; font-size: 11px; margin: 0 0 10px 0; }
        .metrics-grid { display: flex; flex-wrap: wrap; gap: 10px; }
        .metric-card { flex: 1 1 140px; border: 1px solid #E0E0E0; border-radius: 8px;
                       padding: 10px 12px; background: #FAFAFA; min-width: 120px; }
        .metric-value { font-size: 18px; font-weight: 700; color: #1B5E20; }
        .metric-label { font-size: 11px; color: #666; margin-top: 2px; }
        .chart-wrap { text-align: center; padding: 6px 0; }
        .data-table { width: 100%; border-collapse: collapse; font-size: 11px; }
        .data-table th { background: #E8F5E9; color: #1B5E20; text-align: left;
                         padding: 6px 8px; border: 1px solid #C8E6C9; }
        .data-table td { padding: 5px 8px; border: 1px solid #E0E0E0; }
        .data-table tr:nth-child(even) td { background: #FAFAFA; }
    )CSS";
    html += "</style></head><body>";

    html += "<div class=\"page-header\"><h1>" + title + "</h1>";
    if (!subtitle.isEmpty())
        html += "<div class=\"subtitle\">" + subtitle + "</div>";
    html += "<div class=\"generated\">Generated: " + generatedAt + "</div>";
    html += filtersHtml;
    html += "</div>";

    html += body;

    // Inline Chart.js + build all charts synchronously (animations disabled).
    html += "<script>" + chartJsSource() + "</script>";
    html += "<script>";
    html += "var CHART_CONFIGS = " + configsJson + ";";
    html += R"JS(
        try {
            CHART_CONFIGS.forEach(function(c) {
                var el = document.getElementById(c.canvasId);
                if (el) { new Chart(el.getContext('2d'), c.config); }
            });
        } catch (e) { console.error('chart render error', e); }
    )JS";
    html += "</script>";


    html += "</body></html>";
    return html;
}
