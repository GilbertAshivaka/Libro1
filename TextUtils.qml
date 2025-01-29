import QtQuick

QtObject {
    id: textUtils

    function truncateText(text, maxLength) {
        if (text.length > maxLength) {
            return text.substring(0, maxLength - 3) + "...";
        }
        return text;
    }

    function calculateMaxLength(width, averageCharWidth) {
        return Math.floor(width / averageCharWidth);
    }
}
