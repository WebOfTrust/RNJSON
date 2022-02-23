# RNJSON

Data structure for encoding and decoding arbitrary JSON in Swift.

This is a full JSONEncoder/JSONDecoder replacement. That allows for features like maintaining exact decimal representations of numbers (avoiding
float rounding), maintaining key order, and allowing duplicate keys. 

[![Swift 5.5](https://img.shields.io/badge/Swift-5.5-blue.svg)](https://swift.org/download/)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Swift](https://github.com/WebOfTrust/rnjson/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/WebOfTrust/rnjson/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/WebOfTrust/RNJSON/branch/main/graph/badge.svg?token=yWrlgQ4czu)](https://codecov.io/gh/WebOfTrust/RNJSON)


#### Why

RNJSON is used as part of the KERI-swift implementation. In KERI when we sign events, we sign the data over the wire. So we need to ensure that everyone serializes all events exactly the same without the need for any kind of "normalization".  So KERI events must preserve insertion order of all fields in all events so all serializations are identical and signatures can verify (@pfeairheller).

Original upstream work by @rnapier, and we appreciate it.

If you just want "arbitrary JSON" that works with stdlib, see
https://stackoverflow.com/questions/65901928/swift-jsonencoder-encoding-class-containing-a-nested-raw-json-object-literal/65902852#65902852
