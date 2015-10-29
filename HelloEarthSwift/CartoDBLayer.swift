//
//  CartoDBLayer.swift
//  HelloEarthSwift
//
//  Created by Daniel Martín García on 14/10/15.
//  Copyright © 2015 Daniel Martín García. All rights reserved.
//

import Foundation


class CartoDBLayer: NSObject, MaplyPagingDelegate {
    
    private var _minZoom = Int32(0)
    private var _maxZoom = Int32(0)
    
    private var search: String
    private var opQueue: NSOperationQueue?
    
    //Create with search string we'll use
    
    init(search: String){
        
        self.search = search
        self.opQueue = NSOperationQueue()
        super.init()
    }
    
    func minZoom() -> Int32 {
        return _minZoom
    }
    func maxZoom() -> Int32 {
        return _maxZoom
    }
    
    func setMinZoom(value: Int32) {_minZoom = value}
    func setMaxZoom(value: Int32) {_maxZoom = value}
    
    func startFetchForTile(tileID: MaplyTileID, forLayer layer: MaplyQuadPagingLayer) {
        // bounding box for tile
        let ll = UnsafeMutablePointer<MaplyCoordinate>.alloc(1)
        let ur = UnsafeMutablePointer<MaplyCoordinate>.alloc(1)
        
        layer.geoBoundsforTile(tileID, ll: ll, ur: ur)
        
        let bbox = MaplyBoundingBox(ll: ll.memory, ur: ur.memory)
        
        ll.dealloc(1)
        ur.dealloc(1)
        
        let urlReq = constructRequest(bbox)
        
        NSURLConnection.sendAsynchronousRequest(urlReq, queue: opQueue!)
            { (response, data, error) -> Void in
                // parse the resulting GeoJSON
                let vecObj = MaplyVectorObject(fromGeoJSON: data!)
                
                // display a transparent filled polygon
                let filledObj = layer.viewC!.addVectors([vecObj!],
                    desc: [
                        kMaplyColor: UIColor(red: 0.25, green: 0.0, blue: 0.0, alpha: 0.25),
                        kMaplyFilled: true,
                        kMaplyEnable: false],
                    mode: MaplyThreadMode.Current)
                
                // display a line around the lot
                let outlineObj = layer.viewC!.addVectors([vecObj!],
                    desc: [
                        kMaplyColor: UIColor.redColor(),
                        kMaplyFilled: false,
                        kMaplyEnable: false],
                    mode: MaplyThreadMode.Current)
                
                // keep track of it in the layer
                layer.addData([filledObj!, outlineObj!], forTile: tileID)
                
                // let the layer know the tile is done
                layer.tileDidLoad(tileID)
        }
    }
    
    func constructRequest(bbox: MaplyBoundingBox) -> NSURLRequest {
        let toDeg = Float(180.0/M_PI)
        let query = NSString(format: search, bbox.ll.x * toDeg, bbox.ll.y * toDeg,bbox.ur.x * toDeg, bbox.ur.y * toDeg)
        var encodeQuery = query.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let range = Range<String.Index>(start: encodeQuery!.startIndex, end: encodeQuery!.endIndex)
        encodeQuery = encodeQuery!.stringByReplacingOccurrencesOfString("&", withString: "%26", options: [], range: range)
        let fullUrl = NSString(format: "https://pluto.cartodb.com/api/v2/sql?format=GeoJSON&q=%@", encodeQuery!) as String
        let urlReq = NSURLRequest(URL: NSURL(string: fullUrl)!)
        
        return urlReq
    }
}