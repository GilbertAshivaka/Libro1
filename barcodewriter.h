#ifndef BARCODEWRITER_H
#define BARCODEWRITER_H
#include <QObject>
#include <QPainter>
#include <QFont>
#include <QFontMetrics>
#include "BarcodeFormat.h"
#include "BitMatrix.h"
#include "MultiFormatWriter.h"
#include <QDebug>
#include <QImage>
#include <QRegularExpression>


namespace ZXingQt {
inline QImage WriteBarcode(QStringView text, ZXing::BarcodeFormat format, bool includeText = true){
    using namespace ZXing;
    auto writer = MultiFormatWriter(format);
    auto matrix = writer.encode(text.toString().toStdString(), 300, 200);
    auto bitmap = ToMatrix<uint8_t>(matrix);
    QImage barcodeImage = QImage(bitmap.data(), bitmap.width(), bitmap.height(), bitmap.width(), QImage::Format::Format_Grayscale8).copy();

    if (includeText) {
        // create a large image to accommodate barcode and text
        int textHeight = 30; // Height allocated for text
        QImage completeImage(barcodeImage.width(), barcodeImage.height() + textHeight, QImage::Format_RGB32);
        completeImage.fill(Qt::white);

        //draw barcode on the image
        QPainter painter(&completeImage);
        painter.drawImage(0, 0, barcodeImage);

        //draw text under the barcode
        painter.setPen(Qt::black);
        QFont font("Arial", 10);
        painter.setFont(font);

        // center the text
        QFontMetrics metrics(font);
        int textWidth = metrics.horizontalAdvance(text.toString());
        int x = (completeImage.width() - textWidth) / 2;
        int y = barcodeImage.height() + textHeight - 10; // Position text near bottom

        painter.drawText(x, y, text.toString());
        painter.end();

        return completeImage;
    }

    return barcodeImage;
}
}// namespace ZXingQt

class BarcodeWriter : public QObject
{
    Q_OBJECT
public:
    explicit BarcodeWriter(QObject *parent = nullptr)
        : QObject(parent)
    {}

    Q_PROPERTY(QString imageUrl READ imageUrl WRITE setImageUrl NOTIFY imageUrlChanged)
    QString imageUrl() const
    {
        return m_imageUrl;
    }

    void setImageUrl(const QString &newUrl)
    {
        if (newUrl != m_imageUrl) {
            m_imageUrl = newUrl;
            emit imageUrlChanged();
        }
    }

public slots:
    QImage writeAndSaveBarcode(const QString &format, const QString &text, const QString &title = "", const QString &author = "", bool includeText = true)
    {
        if (format.isEmpty() || text.isEmpty()) {
            qDebug() << "Cannot generate barcode out of empty content.";
            return QImage();
        }

        auto barcodeFormat = ZXing::BarcodeFormatFromString(format.toStdString());
        auto result = ZXingQt::WriteBarcode(QStringView(text), barcodeFormat, includeText);

        QString identifier;
        if (!title.isEmpty()){
            QString safeTitle = title.left(20).simplified()
                                    .replace(" ", "_")
                                    .replace(QRegularExpression("[\\\\/:*?\"<>|]"), "");

            identifier += safeTitle;
        }

        if (!author.isEmpty()){
            QString safeAuthor = author.split(" ").last().left(10).simplified()
                                     .replace(" ", "_")
                                     .replace(QRegularExpression("[\\\\/:*?\"<>|]"), "");

            identifier += "_" + safeAuthor;
        }

        if (identifier.isEmpty()){
            identifier = text;
        }else{
            identifier += text;
        }

        QString filePath = "C:/Users/Admin/Downloads/Barcodes/" + identifier + ".png";
        result.save(filePath);
        setImageUrl("file:///" + filePath);
        emit barcodeSaved();

        return result;
    }

signals:
    void barcodeSaved();
    void imageUrlChanged();

private:
    QString m_imageUrl;
};

#endif // BARCODEWRITER_H
