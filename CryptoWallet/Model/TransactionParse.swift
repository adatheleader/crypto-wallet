//
//  TransactionParse.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 22.11.2017.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import Foundation
import JSONJoy

struct Transaction: JSONJoy {
    var balance: String
    var block_height: Int
    var double_spend: Int
    var fee: Int
    var hash: String
    var inputs: [Inputs]
    var lock_time: Int
    var out: Out
    var relayed_by: String
    var result: String
    var size: Int
    var time: Int
    var tx_index: Int
    var ver: Int
    var vin_sz: Int
    var vout_sz: Int
    var weight: Int
    
    init(_ decoder: JSONLoader) throws{
        balance = try decoder["balance"].get()
        block_height = try decoder["block_height"].get()
        double_spend = try decoder["double_spend"].get()
        fee = try decoder["fee"].get()
        hash = try decoder["hash"].get()
        inputs = try [Inputs(decoder["inputs"])]
        lock_time = try decoder["lock_time"].get()
        out = try Out(decoder["out"])
        relayed_by = try decoder["relayed_by"].get()
        result = try decoder["result"].get()
        size = try decoder["size"].get()
        time = try decoder["time"].get()
        tx_index = try decoder["tx_index"].get()
        ver = try decoder["ver"].get()
        vin_sz = try decoder["vin_sz"].get()
        vout_sz = try decoder["vout_sz"].get()
        weight = try decoder["weight"].get()
    }
}

struct Inputs: JSONJoy {
    var prev_out: Out
    var script: String
    var sequence: Int
    var witness: String
    init(_ decoder: JSONLoader) throws{
        prev_out = try Out(decoder["prev_out"])
        script = try decoder["script"].get()
        sequence = try decoder["sequence"].get()
        witness = try decoder["witness"].get()
    }
}

struct Out: JSONJoy {
    var addr: String
    var n: Int
    var script: String
    var spent: Int
    var tx_index: Int
    var type: Int
    var value: Int
    
    init(_ decoder: JSONLoader) throws{
        addr = try decoder["addr"].get()
        n = try decoder["n"].get()
        script = try decoder["script"].get()
        spent = try decoder["spent"].get()
        tx_index = try decoder["tx_index"].get()
        type = try decoder["type"].get()
        value = try decoder["value"].get()
        
    }
}
