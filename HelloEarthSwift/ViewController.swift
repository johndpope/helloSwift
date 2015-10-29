//
//  ViewController.swift
//  HelloEarthSwift
//
//  Created by Daniel Martín García on 13/10/15.
//  Copyright © 2015 Daniel Martín García. All rights reserved.
//

import UIKit


class ViewController: UIViewController, WhirlyGlobeViewControllerDelegate, MaplyViewControllerDelegate{
    
    
    private var theGlobeView: WhirlyGlobeViewController?
    private var theMapView: MaplyViewController?
    private var theView: MaplyBaseViewController?
    
    private let isMap = true
    private let useLocalTitles = true
    private var vectorDict: [String:AnyObject]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (!isMap){
            theGlobeView = WhirlyGlobeViewController()
            theView = theGlobeView
        }
        else{
            theMapView = MaplyViewController();
            theView = theMapView
        }
        self.view.addSubview(theView!.view)
        theView!.view.frame = self.view.bounds
        addChildViewController(theView!)
        
        if let theGlobeView = theGlobeView{
            theGlobeView.delegate = self;
        }
        
        if let theMapView = theMapView{
            theMapView.delegate = self;
        }
        //we want a black background for a globe, a white background for a map

        theView!.clearColor = (theGlobeView != nil) ? UIColor.blackColor() : UIColor.whiteColor();
        
        // and thirty fps if we can get it ­ change this to 3 if you find your app is struggling
        
        theView!.frameInterval = 5;
        
        let layer : MaplyQuadImageTilesLayer
        if (useLocalTitles){
            
            //set up the data source

            let titleSource = MaplyMBTileSource(MBTiles: "geography-class_medres")
            
            //set up the layer
            
            layer = MaplyQuadImageTilesLayer(coordSystem: titleSource!.coordSys, tileSource: titleSource!)!
        }
        else{
            //Because this is a remote tile set, we'll want a cache directory
            let baseCacheDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] 
            let aerialTilesCacheDir = "\(baseCacheDir)/osmtiles/"
            let maxZoom = Int32(18)
            
            //MapQuest Open Aerial Tiles, Courtesy of Mapquest
            // Portions Courtesy NASA/JPL­Caltech and U.S. Depart. of Agriculture, Farm Service Agency
            let tileSource = MaplyRemoteTileSource(baseURL: "http://otile1.mqcdn.com/tiles/1.0.0/sat/", ext: "png", minZoom: 0, maxZoom: maxZoom)
            layer = MaplyQuadImageTilesLayer(coordSystem: tileSource!.coordSys, tileSource: tileSource!)!
        }
        
        
        layer.handleEdges = (theGlobeView != nil)
        layer.coverPoles = (theGlobeView != nil)
        layer.requireElev = false
        layer.waitLoad = false
        layer.drawPriority = 0
        layer.singleLevelLoading = false
        theView!.addLayer(layer)
        
        //start up over Madrid, center of the old-world
        
        if let theGlobeView = theGlobeView{
            theGlobeView.height = 0.8
            theMapView?.viewWrap = true
            theGlobeView.animateToPosition(MaplyCoordinateMakeWithDegrees(-3.6704803, 40.5023056), time: 1.0)
        }
        else if let theMapView = theMapView{
            insertMapZen(theMapView)
            theMapView.height = 1.0
            theMapView.animateToPosition(MaplyCoordinateMakeWithDegrees(-3.6704803, 40.5023056), time: 1.0)
        }
        vectorDict = [
            kMaplyColor: UIColor.whiteColor(),
            kMaplySelectable: true,
            kMaplyVecWidth: 4.0
        ]
        //addCountries()
        //addBars()
        //addSpheres()
        //addBuildings()
        
    }
    
    private func insertMapZen(mapVC: MaplyViewController){
        let cacheDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
        
        let thisCacheDir = "\(cacheDir)/mapzen-vectiles/"
        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("MapzenStyles", ofType: "json", inDirectory: "mapzen_vectors")
        
        MaplyMapnikVectorTiles.StartRemoteVectorTilesWithURL(
            "http://vector.mapzen.com/osm/all/",
            ext: "mapbox",
            minZoom: Int32(0),
            maxZoom: Int32(14),
            accessToken: "vector-tiles-ejNTZ28",
            style: path!,
            styleType: MapnikStyleType.MapboxGLStyle,
            cacheDir: thisCacheDir, viewC: mapVC,
            success: { (maplyMapnikVectorTiles) -> Void in
                let pagelayer = MaplyQuadPagingLayer.init(coordSystem: MaplySphericalMercator.init(webStandard: ()), delegate: maplyMapnikVectorTiles)
                pagelayer?.numSimultaneousFetches = 4
                pagelayer?.flipY = false;
                pagelayer?.importance = 1024*1024
                pagelayer?.useTargetZoomLevel = true
                pagelayer?.singleLevelLoading = true
                mapVC.addLayer(pagelayer!)
                
            }) { (error) -> Void in
                NSLog("Failed to load Mapnik vector tiles because: %@", error)
        }
    }

    private func addCountries(){
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        dispatch_async(queue){
            let bundle = NSBundle.mainBundle()
            let allOutLines = bundle.pathsForResourcesOfType("", inDirectory: "country_json_50m")
            
            for outline in allOutLines {
                if let jsonData = NSData(contentsOfFile: outline){
                    let wgVecObj = MaplyVectorObject(fromGeoJSON: jsonData)
                    // the admin tag from the country outline geojson has the country name ­ save
                    if let attrs = wgVecObj!.attributes, vecName = attrs.objectForKey("ADMIN") as? NSObject{
                        wgVecObj!.userObject = vecName
                        
                        if vecName.description.characters.count > 0{
                            
                            let label = MaplyScreenLabel()
                            label.text = vecName.description
                            label.loc = wgVecObj!.center()
                            label.selectable  = true
                            label.layoutImportance = 10
                            self.theView?.addScreenLabels([label], desc: [
                                kMaplyFont: UIFont.boldSystemFontOfSize(24.0),
                                kMaplyTextOutlineColor: UIColor.blackColor(),
                                kMaplyTextOutlineSize: 2.0,
                                kMaplyColor: UIColor.whiteColor()])
                        }
                        
                    }
                    
                    // add the outline to our view
                    let compObj = self.theView?.addVectors([wgVecObj!], desc: self.vectorDict)
                    // If you ever intend to remove these, keep track of the MaplyComponentObjects above.

                }
            }
        }
        
    }
    
    private func addBars(){
        
        
        let capitals = [
            MaplyCoordinateMakeWithDegrees(-122.4192,37.7793),
            MaplyCoordinateMakeWithDegrees(-77.036667, 38.895111),
            MaplyCoordinateMakeWithDegrees(120.966667, 14.583333),
            MaplyCoordinateMakeWithDegrees(55.75, 37.616667),
            MaplyCoordinateMakeWithDegrees(-0.1275, 51.507222),
            MaplyCoordinateMakeWithDegrees(-66.916667, 10.5),
            MaplyCoordinateMakeWithDegrees(139.6917, 35.689506),
            MaplyCoordinateMakeWithDegrees(166.666667, -77.85),
            MaplyCoordinateMakeWithDegrees(-58.383333, -34.6),
            MaplyCoordinateMakeWithDegrees(-74.075833, 4.598056),
            MaplyCoordinateMakeWithDegrees(-79.516667, 8.983333)
        ]
        
        let icon = UIImage (named: "marker-stroked-24@2x.png")
        
        let markers = capitals.map {
            cap -> MaplyScreenMarker in let marker = MaplyScreenMarker()
            marker.image = icon
            marker.loc = cap
            marker.size = CGSizeMake(140, 140)
            return marker
        }
        
        theView?.addScreenMarkers(markers, desc: nil)
    }
    
    private func addSpheres(){
        
        let capitals = [
            MaplyCoordinateMakeWithDegrees(-122.4192,37.7793),
            MaplyCoordinateMakeWithDegrees(-77.036667, 38.895111),
            MaplyCoordinateMakeWithDegrees(120.966667, 14.583333),
            MaplyCoordinateMakeWithDegrees(55.75, 37.616667),
            MaplyCoordinateMakeWithDegrees(-0.1275, 51.507222),
            MaplyCoordinateMakeWithDegrees(-66.916667, 10.5),
            MaplyCoordinateMakeWithDegrees(139.6917, 35.689506),
            MaplyCoordinateMakeWithDegrees(166.666667, -77.85),
            MaplyCoordinateMakeWithDegrees(-58.383333, -34.6),
            MaplyCoordinateMakeWithDegrees(-74.075833, 4.598056),
            MaplyCoordinateMakeWithDegrees(-79.516667, 8.983333)]
        
        //convert capitals into spheres. Let's do it functional!
        
        let spheres = capitals.map { capital -> MaplyShapeSphere in let sphere = MaplyShapeSphere()
            sphere.center = capital
            sphere.radius = 0.01
            return sphere
        }
        self.theView?.addShapes(spheres, desc: [kMaplyColor: UIColor(red: 0.75, green: 0.0, blue: 0.0, alpha: 0.75)])
        
    }
    
    private func addAnnotationWithTitle(title: String, subtitle: String, loc:MaplyCoordinate){
        
        theView?.clearAnnotations()
        
        let a = MaplyAnnotation()
        a.title = title
        a.subTitle = subtitle
        
        theView?.addAnnotation(a, forPoint: loc, offset: CGPointZero)
    }
    
    
    func globeViewController(viewC: WhirlyGlobeViewController, didTapAt coord: WGCoordinate) {
        let subtitle = NSString(format: "(%.2fN, %.2fE)", coord.y*57.296,coord.x*57.296) as String
        addAnnotationWithTitle("Tap!", subtitle: subtitle, loc: coord)
    }
    
    func maplyViewController(viewC: MaplyViewController, didTapAt coord: MaplyCoordinate) {
        let subtitle = NSString(format: "(%.2fN, %.2fE)", coord.y*57.296,coord.x*57.296) as String
        addAnnotationWithTitle("Tap!", subtitle: subtitle, loc: coord)
    }
    
    private func handleSelection(selectedObject: NSObject) {
        if let selectedObject = selectedObject as? MaplyVectorObject {
            let loc = UnsafeMutablePointer<MaplyCoordinate>.alloc(1)
            if selectedObject.centroid(loc) {
                let title = "Selected:"
                let subtitle = selectedObject.userObject as! String
                addAnnotationWithTitle(title, subtitle: subtitle, loc: loc.memory)
            }
            loc.dealloc(1)
        }
        else if let selectedObject = selectedObject as? MaplyScreenMarker {
            let title = "Selected:"
            let subtitle = "Screen Marker"
            addAnnotationWithTitle(title, subtitle: subtitle, loc: selectedObject.loc)
        }
    }
    
    // This is the version for a globe
    func globeViewController(viewC: WhirlyGlobeViewController, didSelect selectedObj: NSObject) {
        handleSelection(selectedObj)
    }
    
    // This is the version for a map
    func maplyViewController(viewC: MaplyViewController, didSelect selectedObj: NSObject) {
        handleSelection(selectedObj)
    }
    
    private func addBuildings(){
        
        let search = "SELECT the_geom,address,ownername,numfloors FROM mn_mappluto_13v1 WHERE the_geom && ST_SetSRID(ST_MakeBox2D(ST_Point(%f, %f), ST_Point(%f, %f)), 4326) LIMIT 2000;"
        
        let cartoLayer = CartoDBLayer(search: search)
        cartoLayer.setMinZoom(15);
        cartoLayer.setMaxZoom(15);
        let coordSys = MaplySphericalMercator(webStandard: ())
        let quadLayer = MaplyQuadPagingLayer(coordSystem: coordSys, delegate: cartoLayer)
        theView?.addLayer(quadLayer!)
    }
    
}

