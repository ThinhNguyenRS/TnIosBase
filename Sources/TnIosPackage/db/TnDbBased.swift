//
//  TnDbBased.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 10/4/21.
//

import Foundation

class TnDbBased: NSObject {
    let name: String
    let db: TnDbSqlite

    init(name: String) {
        self.name = name
        db = TnDbSqlite(name + ".db")
    }
    
    func open() throws {
        TnLogger.debug(name, "open database ...")
        try db.open()
        TnLogger.debug(name, "open done !")
    }
    func close() {
        db.close()
    }
    
    deinit {
        TnLogger.debug("TnDbBased", name, "deinit !")
        self.close()
    }
}

