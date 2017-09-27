//
//  TestRawTransaction.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 25.09.17.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import Foundation
import IDZSwiftCommonCrypto


let Bob_addr = "1NWzVg38ggPoVGAG2VWt6ktdWMaV6S1pJK"
//let Bob_hashed_pubkey = base58.b58decode_check(Bob_addr)[1:].encode("hex")

let Bob_privte_key     = "CF933A6C602069F1CBC85990DF087714D7E86DF0D0E48398B7D8953E1F03534A"
let Charlie_addr     = "17X4s8JdSdLxFyraNUDBzgmnSNeZpjm42g"
//let Charlie_hashed_pubkey = base58.b58decode_check(Charlie_addr)[1:].encode("hex")

let txid1 = "3df07acef5b210d34c9dfe69708cc26d0f8e11a63ee1886973b30f4ff196fcd6"
let txid2 = "dc335bda9f4a39243e175b02d44ad454ee5b56b211da8a9aab9cd025687109bc"

func flip_byte_order(text: String) {
//    let flipped = "".join(reversed([text[i=i+2] for i in range(0, text.count, 2)]))

//    return flipped
    
    var str = ""
    for i in stride(from: 0, to: text.count, by: 2) {
        let flipped = str
        print (str)
    }
}

// Total amount 0.00148156 BTC
// Bob wants to send Charlie 0.001 BTC and he wants to leave 0.0002 which means Bob will get back (change) 0.00028156

let to_Charlie = 0.98156 //#BTC
let to_Bob = 0.00028156 //#BTC (this is the change)

struct raw_tx {
    var version: [String: Int] = ["<L": 1]
    var tx_in_count: [String: Int] = ["<B": 2]
    var txin1: [String: Any] = [:] //temp
    var txin2: [String: Any]  = [:] //temp
    var tx_out_count: [String: Int] = ["<B": 2]
    var tx_out1: [String: Any] = [:] //temp
    var tx_out2: [String: Any] = [:] //temp
    var lock_time: [String: Int] = ["<L": 0]
    var hash_code: [String: Int] = ["<L": 1]
}

var rtx = raw_tx()
/*rtx.txin1["outpoint"]         = flip_byte_order(string: txid1).decode("hex")
rtx.txin1["outpoint_index"] = ["<L": 0]
rtx.txin1["script_bytes"]    = 0 //tem
rtx.txin1["script"]            = ("76a914%s88ac" % Bob_hashed_pubkey).decode("hex")
rtx.txin1["script_bytes"]    = ["<B", (length(rtx.txin1["script"]))]
rtx.txin1["sequence"]        = "ffffffff".decode("hex")

rtx.txin2["outpoint"]         = flip_byte_order(txid2).decode("hex")
rtx.txin2["outpoint_index"] = struct.pack("<L", 1)
rtx.txin2["script_bytes"]    = 0 #temp
rtx.txin2["script"]            = ("76a914%s88ac" % Bob_hashed_pubkey).decode("hex")
rtx.txin2["script_bytes"]    = struct.pack("<B", (len(rtx.txin2["script"])))
rtx.txin2["sequence"]        = "ffffffff".decode("hex")

rtx.tx_out1["value"]        = struct.pack("<Q", 100000) #send to Charlie
rtx.tx_out1["pk_script_bytes"] = 0 #temp
rtx.tx_out1["script"]        = ("76a914%s88ac" % Charlie_hashed_pubkey).decode("hex")
rtx.tx_out1["pk_script_bytes"] = struct.pack("<B", (len(rtx.tx_out1["script"])))

rtx.tx_out2["value"]        = struct.pack("<Q", 28156) #change back to Bob
rtx.tx_out2["pk_script_bytes"] = 0 #temp
rtx.tx_out2["script"]        = ("76a914%s88ac" % Bob_hashed_pubkey).decode("hex")
rtx.tx_out2["pk_script_bytes"] = struct.pack("<B", (len(rtx.tx_out2["script"])))

tx_to_sign1 = (

rtx.version
+ rtx.tx_in_count
+ rtx.txin1["outpoint"]
+ rtx.txin1["outpoint_index"]
+ rtx.txin1["script_bytes"]
+ rtx.txin1["script"]
+ rtx.txin1["sequence"]
+ rtx.txin2["outpoint"]
+ rtx.txin2["outpoint_index"]
+ struct.pack("<B",0)
+ "".decode("hex")

+ rtx.txin2["sequence"]
+ rtx.tx_out_count
+ rtx.tx_out1["value"]
+ rtx.tx_out1["pk_script_bytes"]
+ rtx.tx_out1["script"]
+ rtx.tx_out2["value"]
+ rtx.tx_out2["pk_script_bytes"]
+ rtx.tx_out2["script"]
+ rtx.lock_time
+rtx.hash_code

)


tx_to_sign2 = (

rtx.version
+ rtx.tx_in_count
+ rtx.txin1["outpoint"]
+ rtx.txin1["outpoint_index"]
+ struct.pack("<B",0)
+ "".decode("hex")

+ rtx.txin1["sequence"]
+ rtx.txin2["outpoint"]
+ rtx.txin2["outpoint_index"]
+ rtx.txin2["script_bytes"]
+ rtx.txin2["script"]
+ rtx.txin2["sequence"]
+ rtx.tx_out_count
+ rtx.tx_out1["value"]
+ rtx.tx_out1["pk_script_bytes"]
+ rtx.tx_out1["script"]
+ rtx.tx_out2["value"]
+ rtx.tx_out2["pk_script_bytes"]
+ rtx.tx_out2["script"]
+ rtx.lock_time
+rtx.hash_code

)*/


//let hashed_tx1 = ("tx_to_sign1")
let hashed_tx1 = Digest(algorithm: .sha256).update(buffer: "tx_to_sign1", byteCount: 256)?.final()
let hashed_tx2 = Digest(algorithm: .sha256).update(buffer: "tx_to_sign2", byteCount: 256)?.final()

sk = ecdsa.SigningKey.from_string(Bob_privte_key.decode("hex"), curve = ecdsa.SECP256k1)

vk = sk.verifying_key

public_key = ('\04' + vk.to_string()).encode("hex")

signature1 = sk.sign_digest(hashed_tx1, sigencode = ecdsa.util.sigencode_der)

signature2 = sk.sign_digest(hashed_tx2, sigencode = ecdsa.util.sigencode_der)

#print "signature:" + signature.encode("hex")

sigscript1 = (
signature1
+ '\01'
+ struct.pack("<B", len(public_key.decode("hex")))
+ public_key.decode("hex")
)


sigscript2 = (
signature2
+ '\01'
+ struct.pack("<B", len(public_key.decode("hex")))
+ public_key.decode("hex")
)

#print "sigscript:" + sigscript.encode("hex")

real_tx = (

rtx.version
+ rtx.tx_in_count
+ rtx.txin1["outpoint"]
+ rtx.txin1["outpoint_index"]
+ struct.pack("<B", (len(sigscript1) + 1))
+ struct.pack("<B", len(signature1) + 1)
+ sigscript1
+ rtx.txin1["sequence"]
+ rtx.txin2["outpoint"]
+ rtx.txin2["outpoint_index"]
+ struct.pack("<B", (len(sigscript2) + 1))
+ struct.pack("<B", len(signature2) + 1)
+ sigscript2
+ rtx.txin2["sequence"]
+ rtx.tx_out_count
+ rtx.tx_out1["value"]
+ rtx.tx_out1["pk_script_bytes"]
+ rtx.tx_out1["script"]
+ rtx.tx_out2["value"]
+ rtx.tx_out2["pk_script_bytes"]
+ rtx.tx_out2["script"]
+ rtx.lock_time

)            //yay!

print real_tx.encode("hex")
