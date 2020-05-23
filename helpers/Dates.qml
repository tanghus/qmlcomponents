/*
  Copyright (c) 2020 Thomas Tanghus
  All rights reserved.

  You may use this file under the terms of BSD license in the LICENSE
  file distributed with the software.
*/
pragma Singleton

import QtQuick 2.6

QtObject {
    /*
     * Date and times:
     * When passing timestamps use seconds, not miliseconds, for historical reasons.
     * Internally in functions milliseconds can be used.
     */

    // Pad a single digit number with zeros
    /*function pad(n, l, z) {
        l = l ? l : 2
        z = typeof z === "string" || typeof z === "number" ? z : "0"
        return (String(z).repeat(l) + String(n)).slice(String(n).length)
    }
    */
    // TODO: Test zeropad instead.
    function pad(s) {
        return (s < 10) ? '0' + s : s;
    }

    /*function pad(number, length) {
        var n = typeof length === "number" ? length : 2

        var str = '' + number;
        while (str.length < length) {
            str = '0' + str;
        }

        return str;
    }*/

    // @returns a string similar to '2019-24-12'
    // https://doc.qt.io/archives/qt-5.6/qml-qtqml-qt.html#formatDateTime-method
    // Qt.formatDate(date, "dd-MM-yyyy")
    function paddedDate(date) {
        var d = getDateObject(date)
        return "" + d.getFullYear() + "-" + pad(d.getMonth()+1) + "-" + pad(d.getDate())
    }

    // @returns a string similar to '02:25'
    // https://doc.qt.io/archives/qt-5.6/qml-qtqml-qt.html#formatDateTime-method
    // Qt.formatTime(date, "hh:mm")
    function paddedTime(date) {
        var d = getDateObject(date)
        return "" + pad(d.getHours()) + ":" + pad(d.getMinutes())
    }

    // @returns a string similar to '2019-24-12 02:25'
    function paddedDateTime(date) {
        var d = getDateObject(date)
        return paddedDate(d) + " " + paddedTime(d)
    }

    // @returns a Date object for the given date at midnight
    function midnightDate(date) {
        var d = getDateObject(date)
        return dateAtTime(d, 0, 0)   //new Date(paddedDate(d) + " 00:00")
    }

    // @returns a Date *object* for the given date at the given hours and minutes
    function dateAtTime(date, hours, minutes) {
        var d = getDateObject(date)
        //console.log("dateAtTime", hours, minutes)
        d = date ? date : new Date()
        var h = hours ? pad(hours) : "00"
        var m = minutes ? pad(minutes) : "00"

        return new Date(paddedDate(d) + " " + h + ":" + m)
    }

    function hourDifference(d1, d2) {
        var diff = d1.getTime() - d2.getTime()
        return diff/3600000
    }

    function getDateObject(obj) {
        var d
        switch(typeof obj) {
            case 'undefined':
                d = new Date()
                break
            case 'string':
            case 'number':
                d = dateFromTimestamp(obj)
                break
            case 'object':
                if(obj instanceof Date) {
                    d = obj
                }
                break
            default:
                break
        }
        // If nothing return a new one
        d = d ? d : new Date()
        return d
    }

    function dateFromTimestamp(timestamp) {
        if(!timestamp) {
            console.error("dateFromTimestamp called with no arguments.")
            console.trace()
        }

        var d = new Date(0)
        timestamp = String(timestamp).length >= 13
                ? d.setUTCMilliseconds(timestamp) : d.setUTCSeconds(timestamp)
        //console.log("Dates.dateFromTimestamp:", d)
        return d
    }

    // adapted from http://pythonwise.blogspot.in/2009/06/strftime-for-javascript.html
    
    /*
     * To use it , save this gist in a file , import it into the desired QML
     * 
     * call as:
     * 
     * Dates.strftime ( format , dateObj);
     * 
     */
    /* strftime for JavaScript
     *       Field description (taken from http://tinyurl.com/65s2qw)
     *        %a  Locale’s abbreviated weekday name.
     *        %A  Locale’s full weekday name.
     *        %b  Locale’s abbreviated month name.
     *        %B  Locale’s full month name.
     *        %c  Locale’s appropriate date and time representation.
     *        %d  Day of the month as a decimal number [01,31].
     *        %H  Hour (24-hour clock) as a decimal number [00,23].
     *        %I  Hour (12-hour clock) as a decimal number [01,12].
     *        %j  Day of the year as a decimal number [001,366].
     *        %m  Month as a decimal number [01,12].
     *        %M  Minute as a decimal number [00,59].
     *        %p  Locale’s equivalent of either AM or PM.
     *        %S  Second as a decimal number [00,61].
     *        %U  Week number of the year (Sunday as the first day of the week) as a
     *            decimal number [00,53]. All days in a new year preceding the first
     *            Sunday are considered to be in week 0.
     *        %w  Weekday as a decimal number [0(Sunday),6].
     *        %W  Week number of the year (Monday as the first day of the week) as a
     *            decimal number [00,53]. All days in a new year preceding the first
     *            Monday are considered to be in week 0.
     *        %x  Locale’s appropriate date representation.
     *        %X  Locale’s appropriate time representation.
     *        %y  Year without century as a decimal number [00,99].
     *        %Y  Year with century as a decimal number.
     *        %Z  Time zone name (no characters if no time zone exists).
     *        %%  A literal '%' character.
     */
    
    property var days : [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    'Saturday'
    ];
    
    property var months : [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
    ];
    
    function shortname(name) {
        return name.substr(0, 3);
    }
    
    function zeropad(n, size) {
        n = '' + n; /* Make sure it's a string */
        size = size || 2;
        while (n.length < size) {
            n = '0' + n;
        }
        return n;
    }
    
    function twelve(n) {
        return (n <= 12) ? n : 24 - n;
    }
    
    function strftime(format, date) {
        date = date || new Date();
        var fields = {
            a: shortname(days[date.getDay()]),
            A: days[date.getDay()],
            b: shortname(months[date.getMonth()]),
            B: months[date.getMonth()],
            c: date.toString(),
            d: zeropad(date.getDate()),
            H: zeropad(date.getHours()),
            I: zeropad(twelve(date.getHours())),
            /* TEST: j: */
            j: daynumber(date),
            m: zeropad(date.getMonth() + 1),
            M: zeropad(date.getMinutes()),
            p: (date.getHours() >= 12) ? 'PM' : 'AM',
            S: zeropad(date.getSeconds()),
            w: zeropad(date.getDay() + 1),
            /* TEST: W: */
            W: weeknumber(date),
            x: date.toLocaleDateString(),
            X: date.toLocaleTimeString(),
            y: ('' + date.getFullYear()).substr(2, 4),
            Y: '' + date.getFullYear(),
            /* FIXME: Z: 
             * https://stackoverflow.com/questions/9772955/how-can-i-get-the-timezone-name-in-javascript */
            '%' : '%'
        };
        
        var result = '', i = 0;
        while (i < format.length) {
            if (format[i] === '%') {
                result = result + fields[format[i + 1]];
                ++i;
            }
            else {
                result = result + format[i];
            }
            ++i;
        }
        return result;
    }
    
    function epoch2date(epoch) {
        var d = new Date();
        var n = d.getTimezoneOffset() * 60 ;
        epoch = epoch - n ;
        var date = new Date(epoch * 1000);
        return date;
    }
    
    function daynumber(date) {
        var now = date || new Date();
        var start = new Date(now.getFullYear(), 0, 0);
        var diff = (now - start) + ((start.getTimezoneOffset() - now.getTimezoneOffset()) * 60 * 1000);
        var oneDay = 1000 * 60 * 60 * 24;
        return Math.floor(diff / oneDay);
    }
    
    function weeknumber(date) {
        // https://stackoverflow.com/a/7765814/373007
        date = date || new Date()
        var fourjan = new Date(date.getFullYear(), 0, 4)
        return Math.ceil((((date - fourjan) / 86400000) + fourjan.getDay() + 1) / 7)
    }
}
