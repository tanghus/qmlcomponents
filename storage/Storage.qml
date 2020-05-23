/*
  Copyright (c) 2020 Thomas Tanghus
  All rights reserved.

  You may use this file under the terms of BSD license in the LICENSE
  or LICENSE.md file distributed with the software.
*/

import QtQuick 2.6
import QtQuick.LocalStorage 2.0 as LS

QtObject {

    property int version: 2.0
    property string dbName: ""
    property string tblName: ""
    property string dbDescription: dbName;
    // TODO: Check what database version means
    property string dbVersion: ""
    // Other Storage types which database schemas must be created.
    // E.g.
    // dependencies: ["Authour", "Book"]
    property var dependencies: ({})
    /* Table schema example:
    columns: ({
        id: {type:"TEXT"},
        title: {type:"TEXT"},
        start: {type:"TEXT"},
        stop: {type:"TEXT"},
        bookmarked: {type:"INTEGER", default:0},
        notified: {type:"INTEGER", default:0} // To avoid multiple notifications
    })
    */
    property var columns: ({})

    /* IDEA: Add a property "depends" or something like like, to define Storages
      that must be instantiated first.
      Storage {
          dbName: StandardPaths.data
          tblName: "programs"
          property var depends: ["ChannelStorage", "BookmarkStorage"]
      }
      */

    property var key // Obsolete
    property var keys

    // Estimated size of DB in bytes. Just a hint for the engine and is ignored as of Qt 5.0 I think
    property int estimatedSize: 10000
    property var _dbObj
    property bool _hasTable: false

    Component.onCompleted: {
        //console.log("Storage.onCompleted")
        if(key && !keys) {
            console.warn("The 'key' property is obsolete. Use 'keys' instead.")
            Object.defineProperty(this, 'keys', { value: key, writable: false});
            keys = key
        }
        if(dependencies.length > 0) {
            for(var i = 0;i < dependencies.length - 1; i++) {
                console.log("Storage. Creating:", dependencies[i])
                _instantiateStorage(dependencies[i])
            }
        }

        _dbObj = _getDatabase()
        _hasTable = _getTable()
    }

    function _formatException(e, cb) {
        console.log(e.message)
        console.trace()

        if(cb) {
            var response = {"status": "error", "message": e.message}
            cb(response)
        }

        //throw e
    }

    function _getDatabase(cb) {
        if(_dbObj) {
            return _dbObj
        }

        if(!typeof dbName === "string" || !dbName.trim()) {
            _formatException(new Error(qsTr("No database name has been set")),
                function(response) {
                    if(cb) { cb(response) }
            })
        } else {
            try {
                _dbObj = LS.LocalStorage.openDatabaseSync(
                            dbName, dbVersion, dbDescription, estimatedSize
                            );
                if(cb) { cb({"status":"success","result":[]}) }
                return _dbObj
            } catch(e) {
                _formatException(e, function(response) {
                    if(cb) { cb(response) }
                })
            }
        }
    }

    function _getTable(cb) {
        var response = {}

        if(!_dbObj) {
            _getDatabase()
        }
        if(_hasTable) {
            return true
        }

        if(typeof tblName !== "string" || !tblName.trim()) {
            _formatException(new Error(qsTr("No table name has been set")),
                function(response) {
                    if(cb) { cb(response) }
            })
            return false
        }

        var keyString = "", tmpColumns = []
        var sql = "CREATE TABLE IF NOT EXISTS " + tblName

        // The columns
        for(var k in columns) {
            if(columns.hasOwnProperty(k)) {
                // Use switch?
                if(typeof columns[k] === "string") { // "Old" DB schema.
                    tmpColumns.push(k + " " + columns[k])
                } else if(typeof columns[k] === "object") { // Extended DB schema.
                    var col = k + " " + columns[k].type // TEXT, INT etc.
                    col += columns[k].hasOwnProperty("notnull") && columns[k].notnull ? " NOT NULL" :""
                    col += columns[k].hasOwnProperty("default") ? " DEFAULT " + columns[k].default : "" // Default value
                    tmpColumns.push(col)
                } else {
                    _formatException(new Error(qsTr("Column definition must be either 'string' or 'object'.")),
                        function(response) {
                            if(cb) { cb(response) }
                    })
                    return false
                }
            }
        }
        // IDEA: Always add a timestamp. The below only works on inserts, not updates,
        // so there needs to be a trigger
        // https://stackoverflow.com/a/6585590/373007
        //tmpColumns.push("timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP")
        sql += "(" + tmpColumns.join(",")

        // Any key constraints?
        if(keys) {
            keyString = keys.join(",")
        }

        if(keyString) {
            sql += ", PRIMARY KEY(" + keyString + ")"
        }
        sql += ")"

        //console.log("Storage._getTable():", sql)
        executeSQL(sql, function(response) {
            if(cb) { cb(response) }
        }, true) // Note third parameter.
        return true // FIXME: Return usable value.
    }

    /** Insert or update record. If you want to update, you will have to specify
     *    all fields and values or the result will be unpredictable.
     * @param array fields An array with the names of the fields
     *   in the table, you want to have inserted/updated
     * @param array values An array of the values you want
     *   insert/update
     * @param function cb Optional callback function.
     * @return undefined or throws exception
     */
    function set(fields, values, where, cb) {
        var i, updates, sql

        if(!Array.isArray(fields) || !Array.isArray(values)) {
            _formatException(new Error(qsTr("The two first arguments must be arrays.")))
        }
        if(fields.length !== values.length) {
            _formatException(new Error(qsTr("The number of 'values' must match the number of 'fields'")))
        }
        if(!fields.length > 0) {
            _formatException(new Error(qsTr("At least one field to update must be specified")))
            return
        }

        // Check for WHERE conditions
        if(where && Object.keys(where).length) {
            // Create key, value pairs
            sql = "UPDATE " + tblName + " SET "
            updates = []
            for(i = 0; i < fields.length; ++i) {
                updates.push(fields[i] + "=" + sanitize(fields[i], values[i]))
            }
            sql += updates.join(",")
            sql += _constructWhere(where)
        } else {
            var fieldsString = fields.join(",")
            // Escape single-quotes before applying them as delimiters.
            for(var value in values) {
                values[value] = sanitize(fields[value], values[value])
            }
            var valuesString = values.join(",")
            sql = "INSERT OR REPLACE INTO " + tblName
                    + "(" + fieldsString + ")"
                    + " VALUES (" + valuesString + ");"
        }

        executeSQL(sql, function(response) {
            //console.log("Storage.set(). response:", JSON.stringify(response))
            if(cb) { cb(response) }
        })
    }

    /** Retrieve record(s). Currently only callbacks are supported.
     * @param array fields An array with the names of the fields
     *   in the table, you want to have retrieve.
     * @param object where An object with key/value pairs.
     * @param function cb Callback function.
     * @return An array of object(s) (via callback)
     */
    function get(fields, where, sortOrder, cb) {
        var sql = "SELECT "

        // Which fields to return
        if(Array.isArray(fields)) {
            sql += fields.join(",")
        } else if(typeof fields === "string") {
            sql += fields
        } else {
            _formatException(
                new Error(qsTr("fields must be a string or an array.")),
                    function(response) {
                        if(cb) { cb(response)
                    }})
            return
        }

        sql += " FROM "+ tblName
        // The WHERE clauses
        sql += _constructWhere(where)

        // The ORDER BY clauses
        if(sortOrder && sortOrder.length) {
            sql += " ORDER BY " + sortOrder.join(",")
        }

        executeSQL(sql, function(response) {
            if(cb) {
                cb(response)
            }
        })
    }

    /* Remove record(s).
     * @param object where An object with key/value pairs.
     * @param function cb Callback function.
     */
    function remove(where, cb) {
        //console.log("Storage.remove. where:", JSON.stringify(where))
        var sql = "DELETE FROM " + tblName

        // The WHERE clauses
        sql += _constructWhere(where)
        executeSQL(sql, function(response) {
            if(cb) { cb(response) }
        })
    }

    function truncate(cb) {
        var sql = "DELETE FROM " + tblName

        executeSQL(sql, function(response) {
            if(cb) { cb(response) }
        })
    }

    function drop(cb) {
        var sql = "DROP TABLE " + tblName

        executeSQL(sql, function(response) {
            if(cb) { cb(response) }
        })
    }

    // TODO: function max(field, cb)

    function count(where, cb) {
        var q = "COUNT()" // The response from SQLite uses it as key for result.
        if(typeof where === "function") {
            _formatException(new Error(qsTr("The 'count()' function call is invalid")),
                function(response) {
                    if(cb) { cb(response) }
            })
        }

        var sql = "SELECT " + q + " FROM " + tblName
        // The WHERE clauses
        sql += _constructWhere(where)

        executeSQL(sql, function(response) {
            response.result = response.result[0][q]
            if(cb) { cb(response) }
        })
    }

    function executeSQL(sql, cb, bootstrap) {
        if(!bootstrap) {
            _getTable()
        }

        var result

        try { // TODO: Add support for read-only SELECT with db.readTransaction(callback(tx))
            _dbObj.transaction(
                function(tx) {
                    result = tx.executeSql(sql);
                    //console.error("RESULT: Storage.executeSQL()", JSON.stringify(result)) // sql)
                    result["result"] = []
                    result["query"] = sql
                    result["status"] = "success"
                    for (var i = 0; i < result.rows.length; i++) {
                        result["result"].push(result.rows.item(i))
                    }
                    if(cb) {
                        cb(result)
                    }
                }
            )
        } catch(e) {
            console.error("ERROR: Storage.executeSQL()", sql) //JSON.stringify(result)) //
            _formatException(e, function(response) {
                if(cb) { cb(response) }
            })
        }
    }

    // The WHERE clauses
    function _constructWhere(where) {
        var whereList = [], sql = ""
        if(Object.keys(where).length) {
            sql += " WHERE "
        }

        for(var w in where) {
            //console.log("_constructWhere:", w, where[w])
            if (where.hasOwnProperty(w)) {
                if(typeof where[w] === "string" || typeof where[w] === "number") {
                    whereList.push(w + "='" + where[w] + "'")
                } else if(Array.isArray(where[w])) {
                    whereList.push(w + " IN (" + where[w].join(",") + ")")
                } else if(typeof where[w] === "object") {
                    var operator = where[w].operator
                    whereList.push(w + operator + where[w].value)
                }
            }
        }
        sql += whereList.join(" AND ")
        return sql
    }

    function sanitize(key, value) {
        var t = columns[key].hasOwnProperty("type") ? columns[key].type : columns[key]
        //console.log("Storage.sanitize(t)", key, t, t === "TEXT", typeof value === "string")
        //console.log("Storage.sanitize(1)", key, columns[key], typeof value, value)
        if(t === "TEXT" && typeof value === "string") {
            if(value.indexOf("'") !== -1) {
                value = value.replace("'", "\u2019")
            }
            value = "'" + value + "'"
            //console.log("Storage.sanitize(2)", version, key, JSON.stringify(columns[key]), typeof value, value)
        }
        return value
    }

    /*
     * In Env or DKTV keep track of instantiated Requesters to not
     * attempt to create tables more than once.
     * TODO: Move function to Env or DKTV. Or a separate singleton.
     */
    function _instantiateStorage(_type) {
        if(Env.hasRequester()) {
            console.error(qsTr("Storage has already instantiated a"), _type)
            return
        }

        var component = Qt.createComponent(_type+".qml")
        // TODO: Error handling.

        if(typeof _type !== "string") {
            console.error(qsTr("Storage. Cannot create Storage of type:"), "'", typeof _type, "'", _type, component.errorString())
            console.trace()
            return -1;
        }

        var object = component.createObject(null)

        if (component.status === Component.Error) {
            console.error(qsTr("Error creating:"), "'", type, "'", component.errorString())
            console.trace()
            return -1;
        }
        object.destroy()

        /*var incubator = component.incubateObject(parent, { x: 10, y: 10 });
        if (incubator.status !== Component.Ready) {
            incubator.onStatusChanged = function(status) {
                if (status === Component.Ready) {
                    print ("Object", incubator.object, "is now ready!");
                }
            }
        } else {
            print ("Object", incubator.object, "is ready immediately!");
        }*/
    }
}

