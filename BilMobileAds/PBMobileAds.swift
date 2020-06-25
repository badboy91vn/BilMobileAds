//
//  PBMobileAds.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import PrebidMobile
import GoogleMobileAds

public class PBMobileAds {
    
    public static let shared = PBMobileAds()
    
    // Log Status
    private var isLog: Bool = true
    
    private var isConfigSucc: Bool = false
    // MARK: List Config
    private var listAdUnitObj: [AdUnitObj] = []
    
    // MARK: List AD
    var listADBanner: [ADBanner] = []
    var listADIntersititial: [ADInterstitial] = []
    var listADRewarded: [ADRewarded] = []
    
    // MARK: api
    private var configId: String = ""
    private var pbServerEndPoint: String = ""
    
    private init() {
        log("PBMobileAds Init")
    }
    
    public func initialize(configId: String, testMode: Bool = false) {
        if !isLog { Prebid.shared.logLevel = .error }
        
//        Prebid.shared.pbsDebug = true;
        
        self.configId = configId
        
        //Declare in init to the user agent could be passed in first call
        Prebid.shared.shareGeoLocation = true;
        
        // Setup Test Mode
        if testMode {
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers =  [ (kGADSimulatorID as! String), "cc7ca766f86b43ab6cdc92bed424069b"];
        }
        GADMobileAds.sharedInstance().start();
        
        // print("Internet Available: \(Helper.isNetworkAvailable())")
        self.getADConfig();
    }
    
    // MARK: - Get Data Config
    func getAdUnitObj(placement: String) -> AdUnitObj? {
        for config in self.listAdUnitObj {
            if config.placement == placement {
                return config
            }
        }
        return nil
    }
    
    // MARK: Setup PBS
    func setupPBS(host: Host) {
        PBMobileAds.shared.log("Host: \(host.pbHost) | AccountId: \(host.pbAccountId) | storedAuctionResponse: \(host.storedAuctionResponse)")
        
        if host.pbHost == "Appnexus" {
            Prebid.shared.prebidServerHost = PrebidHost.Appnexus
        } else if host.pbHost == "Rubicon" {
            Prebid.shared.prebidServerHost = PrebidHost.Rubicon
        } else if host.pbHost == "Custom" {
            do {
                PBMobileAds.shared.log("Custom URL: \(String(describing: host.url ?? ""))")
                try Prebid.shared.setCustomPrebidServer(url: self.pbServerEndPoint)
                Prebid.shared.prebidServerHost = PrebidHost.Custom
            } catch {
                PBMobileAds.shared.log("URL server incorrect!")
            }
        }
        
        Prebid.shared.prebidServerAccountId = host.pbAccountId;
        Prebid.shared.storedAuctionResponse = host.storedAuctionResponse;
    }
        
    // MARK: - Call API AD
    func getADConfig() {
        self.log("Start Request Config")

        Helper.shared.getAPI(api: Constants.GET_DATA_CONFIG + "?appId=\(self.configId)"){ (res: Result<DataConfig, Error>) in
            switch res{
            case .success(let dataJSON):
                self.log("Fetch Data Succ")
                
                DispatchQueue.main.async{
                    self.isConfigSucc = true
                    
                    self.pbServerEndPoint = dataJSON.pbServerEndPoint
                    
                    // Set all ad type config
                    for item in dataJSON.adunit {
                        self.listAdUnitObj.append(item)
                    }
                    
                    // Call all ad init before
                    self.log("Banner Count: \(self.listADBanner.count)")
                    for ad in self.listADBanner {
                        ad.load()
                    }
                    self.log("Full Count: \(self.listADIntersititial.count)")
                    for ad in self.listADIntersititial {
                        ad.preLoad()
                    }
                    self.log("Rewarded Count: \(self.listADRewarded.count)")
                    for ad in self.listADRewarded {
                        ad.preLoad()
                    }
                }

                break
            case .failure(let err):
                self.log("Failed To Fetch Data: \(err.localizedDescription)")
                self.timerRecall()
                self.isConfigSucc = false
                break
            }
        }
    }
    
    func timerRecall(){
        self.log("Recall Request Config After: \(Constants.RECALL_CONFIGID_SERVER)")
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.RECALL_CONFIGID_SERVER, execute: {
            self.getADConfig();
        })
    }
    
    func log( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        
        if !isLog { return }
        print("[PBMobileAds] \(Date().toString()) | [\(self.sourceFileName(filePath: filename))]:\(line) \(column) | \(funcName) -> \(object)")
    }
    
    func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
    
    
    public func isInitialize() -> Bool {
        return isConfigSucc
    }
    
    public func enableCOPPA() {
        Targeting.shared.subjectToCOPPA = true
    }
    
    public func disableCOPPA() {
        Targeting.shared.subjectToCOPPA = false
    }

}

internal extension Date {
    func toString() -> String {
        return Helper.dateFormatter.string(from: self as Date)
    }
}
