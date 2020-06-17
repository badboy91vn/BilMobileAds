//
//  ADRewarded.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import PrebidMobile
import GoogleMobileAds

public class ADRewarded: NSObject, GADRewardedAdDelegate  {
    
    // MARK: AD View
    weak var adUIView: UIViewController!
    weak var adDelegate: ADRewardedDelegate!
    
    // MARK: AD OBJ
    private let amRequest = DFPRequest() // GADRequest
    private var adUnit: AdUnit!
    private var amRewardedAd: GADRewardedAd!
    
    var placement: String!
    var adUnitObj: AdUnitObj!
    
    // MARK: Properties
    private var adFormatDefault: ADFormat!;
    private var isLoadAfterPreload: Bool = false // Check user gọi load() chưa có AD -> preload và show AD luôn
    private var isFetchingAD: Bool = false // Check có phải đang lấy AD ko
    private var isRecallingPreload: Bool = false // Check đang đợi gọi lại preload
    
    // MARK: - Init + DeInit
    public init(_ adView: UIViewController, placement: String) {
        super.init()
        
        self.adUIView = adView
        self.adDelegate = adView as? ADRewardedDelegate
        
        self.placement = placement
        
        PBMobileAds.shared.listADRewarded.append(self)
    }
    
    deinit {
        PBMobileAds.shared.log("AD Rewarded Deinit")
        self.destroy()
    }
    
    // MARK: - Preload + Load
    func deplayCallPreload() {
        self.isRecallingPreload = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.INTERSTITIAL_RECALL_DEFAULT) {
            self.isRecallingPreload = false
            self.preLoad()
        }
    }
    
    func getAdInfor(isVideo: Bool) -> AdInfor? {
        for infor in self.adUnitObj.adInfor {
            if infor.isVideo == isVideo {
                return infor
            }
        }
        return nil
    }
    
    func handerResult(_ resultCode: ResultCode) {
        if resultCode == ResultCode.prebidDemandFetchSuccess {
            self.amRewardedAd.load(self.amRequest){ error in
                if let error = error {
                    PBMobileAds.shared.log("Load RewardedVideo failed:\(error.localizedDescription)")
                    if !self.isLoadAfterPreload {
                        self.deplayCallPreload()
                    }
                } else {
                    if self.isLoadAfterPreload {
                        if self.amRewardedAd?.isReady == true {
                            self.amRewardedAd?.present(fromRootViewController: self.adUIView, delegate: self)
                        }
                        
                        self.isLoadAfterPreload = false
                    }
                }
                
                self.isFetchingAD = false
            }
        } else {
            if resultCode == ResultCode.prebidDemandNoBids {
                self.adFormatDefault = self.adFormatDefault == .html ? .vast : .html
                if !self.isLoadAfterPreload {
                    self.deplayCallPreload()
                }
            } else if resultCode == ResultCode.prebidDemandTimedOut {
                if !self.isLoadAfterPreload {
                    self.deplayCallPreload()
                }
            }
            
            self.isFetchingAD = false
        }
    }
    
    public func preLoad() {
        PBMobileAds.shared.log("PBMobileAds: \(PBMobileAds.shared.isInitialize()) | isReady: \(self.isReady()) |  isFetchingAD: \(self.isFetchingAD) | |  isRecallingPreload: \(self.isRecallingPreload)")
        if PBMobileAds.shared.isInitialize() == false || self.isReady() == true || self.isFetchingAD == true || self.isRecallingPreload == true { return }
        
        PBMobileAds.shared.log("Preload Rewarded AD")
        
        // Get Data Config
        if self.adUnitObj == nil {
            guard let adUnitObj = PBMobileAds.shared.getAdUnitObj(placement: self.placement) else {
                PBMobileAds.shared.log("Placement is not exist")
                return
            }
            
            self.adUnitObj = adUnitObj
        }
        
        // Check Active
        if !self.adUnitObj.isActive {
            PBMobileAds.shared.log("Ad is not actived")
            return
        }
        
        let adInfor: AdInfor
        // Hien AD Rewarded chi co video
        guard let infor = self.getAdInfor(isVideo: true) else {
            PBMobileAds.shared.log("AdInfor is not exist")
            return
        }
        adInfor = infor
        
        PBMobileAds.shared.setupPBS(host: adInfor.host)
        PBMobileAds.shared.log("[Rewarded Video] - configId: '\(adInfor.configId)' | adUnitID: '\(adInfor.adUnitID)'")
        
        let parameters = VideoBaseAdUnit.Parameters()
        parameters.mimes = ["video/mp4"]
        parameters.protocols = [Signals.Protocols.VAST_2_0]
        parameters.playbackMethod = [Signals.PlaybackMethod.AutoPlaySoundOn]
        parameters.placement = Signals.Placement.InBanner
        
        let vAdUnit = RewardedVideoAdUnit(configId: adInfor.configId)
        vAdUnit.parameters = parameters
        
        self.adUnit = vAdUnit
        self.amRewardedAd = GADRewardedAd(adUnitID: adInfor.adUnitID)
        
        self.isFetchingAD = true
        self.adUnit.fetchDemand(adObject: self.amRequest) { (resultCode: ResultCode) in
            PBMobileAds.shared.log("Prebid demand fetch for DFP \(resultCode.name())")
            self.handerResult(resultCode)
        }
    }
    
    public func load(){
        if self.amRewardedAd?.isReady == true {
            self.amRewardedAd?.present(fromRootViewController: self.adUIView, delegate: self)
        } else {
            PBMobileAds.shared.log("Don't have AD")
            self.isLoadAfterPreload = true
            self.preLoad()
        }
    }
    
    public func destroy(){
        //        if self.isLoadBannerSucc {
        PBMobileAds.shared.log("Destroy Placement: \(String(describing: self.placement))")
        self.isLoadAfterPreload = false
        self.adUnit?.stopAutoRefresh()
        //        }
    }
    
    public func isReady() -> Bool {
        return self.amRewardedAd?.isReady == true ? true : false
    }
    
    // MARK: - Delegate
    public func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        PBMobileAds.shared.log("Reward received with currency: \(reward.type), amount \(reward.amount).")
        PBMobileAds.shared.log("Ad Rewarded Complete")
        self.adDelegate?.rewardedDidReceiveAd?(data: "Ad Rewarded Complete")
    }
    
    public func rewardedAdDidPresent(_ rewardedAd: GADRewardedAd) {
        PBMobileAds.shared.log("AD Rewarded DidPresent")
        self.adDelegate?.rewardedDidPresent?(data: "AD Rewarded DidPresent")
    }
    
    public func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        PBMobileAds.shared.log("AD Rewarded DidDismiss")
        self.adDelegate?.rewardedDidDismiss?(data: "AD Rewarded DidDismiss")
    }
    
    public func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
        PBMobileAds.shared.log(error.localizedDescription)
        self.adDelegate?.rewardedFailToLoad?(data: error.localizedDescription)
    }
    
}

@objc public protocol ADRewardedDelegate {
    
    /// Tells the delegate that the user earned a reward. show completed
    @objc optional func rewardedDidReceiveAd(data: String)
    
    // Called when an interstitial ad request fail.
    @objc optional func rewardedFailToLoad(data: String)
    
    /// Tells the delegate that the rewarded ad failed to present.
    @objc optional func rewardedFailToPresent(data: String)
    
    /// Tells the delegate that the rewarded ad was presented.
    @objc optional func rewardedDidPresent(data: String)
    
    /// Tells the delegate that the rewarded ad was dismissed.
    @objc optional func rewardedDidDismiss(data: String)
    
}

