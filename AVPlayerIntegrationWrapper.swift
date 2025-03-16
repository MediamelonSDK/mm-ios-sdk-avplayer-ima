import Foundation
import UIKit
import AVFoundation
import os
#if os(iOS)
import CoreTelephony
#endif

#if canImport(MediaMelonNowtilus)
import MediaMelonNowtilus
#endif

#if canImport(MediaMelonNowtilustvOS)
#if os(tvOS)
import MediaMelonNowtilustvOS
#endif
#endif

#if canImport(MediaMelonIMA)
import MediaMelonIMA
import GoogleInteractiveMediaAds
#endif

#if canImport(MediaMelonQoE)
import MediaMelonQoE
#endif

#if canImport(MediaMelonQoEtvOS)
#if os(tvOS)
import MediaMelonQoEtvOS
#endif
#endif

#if canImport(MediaMelonIMAtvOS)
#if os(tvOS)
import MediaMelonIMAtvOS
import GoogleInteractiveMediaAds
#endif
#endif

private var AVFoundationPlayerViewControllerKVOContext = 0
private var AVFoundationPlayerViewControllerKVOContextPlayer = 0

//ENABLE SSAI
#if canImport(MediaMelonNowtilus)
public protocol MMSSAIManagerDelegate: AnyObject {
    func notifyMMSSAIAdEvents(eventName: MMSSAIAdSate, adInfo: MMSSAIAdDetails)
    func notifyMMSSAIAdEventsWithTimeline(eventName: MMSSAIAdSate, adTimeline: [MMSSAIAdDetails])
}

extension AVPlayerIntegrationWrapper: GenericAdProtocol {
    public func notifySSAIAdDetailsWithTimeline(eventName: MMSSAIAdSate, adTimeline: [MMSSAIAdDetails]) {
        self.mmssaiManagerDelegate?.notifyMMSSAIAdEventsWithTimeline(eventName: eventName, adTimeline: adTimeline)
    }
    
    public func notifySSAIAdDetails(eventName: MMSSAIAdSate, adInfo: MMSSAIAdDetails) {
        self.mmssaiManagerDelegate?.notifyMMSSAIAdEvents(eventName: eventName, adInfo: adInfo)
    }
}

extension AVPlayerIntegrationWrapper: AVPlayerItemMetadataCollectorPushDelegate {
    public func getVersion() -> String {
        return AVPlayerIntegrationWrapper.shared.sdkVersion
    }
    
    public static func getAdId(adInfo: MMSSAIAdDetails)->String{
        return (adInfo.adId)
    }
    
    public static func getAdTitle(adInfo: MMSSAIAdDetails)->String{
        return (adInfo.adTitle)
    }
    
    public static func getAdIndex(adInfo: MMSSAIAdDetails)->Int{
        return (adInfo.adIndex)
    }
    
    public static func getAdTotalAdsInPod(adInfo: MMSSAIAdDetails)->Int{
        return (adInfo.adTotalAdsInPod)
    }
    
    public static func getAdServer(adInfo: MMSSAIAdDetails)->String{
        return (adInfo.adServer)
    }
    
    public static func getAdDuration(adInfo: MMSSAIAdDetails)->Int64{
        return (adInfo.adDuration)
    }
    
    public static func getAdPosition(adInfo: MMSSAIAdDetails)->String{
        return (adInfo.position)
    }
    
    public static func getAdPlaybackTime(adInfo: MMSSAIAdDetails)->Int64{
        return (adInfo.adCurrentPlaybackTime)
    }
    
    public static func getClickThroughURL(adInfo: MMSSAIAdDetails)->String{
        for adClickEvent in adInfo.adClickEvents
        {
            let eventType =  (adClickEvent.type.rawValue)
            if eventType.contains("ClickThrough") && adClickEvent.url?.absoluteString != nil
            {
                return (adClickEvent.url?.absoluteString)!
            }
        }
        return "None"
    }
    
    public static func getClickTrackingURL(adInfo: MMSSAIAdDetails)->String{
        for adClickEvent in adInfo.adClickEvents
        {
            let eventType =  (adClickEvent.type.rawValue)
            
            if eventType.contains("ClickTracking") && adClickEvent.url?.absoluteString != nil
            {
                return (adClickEvent.url?.absoluteString)!
            }
        }
        return "None"
    }
    
    public static func setMetaDataCollector(player: AVPlayer, collector: AVPlayerItemMetadataCollector, playerItem: AVPlayerItem)
    {
        playerItem.add(collector)
        player.replaceCurrentItem(with: playerItem)
        collector.setDelegate(self.shared, queue: DispatchQueue.main)
    }
    
    public func metadataCollector(_ metadataCollector: AVPlayerItemMetadataCollector, didCollect metadataGroups: [AVDateRangeMetadataGroup], indexesOfNewGroups: IndexSet, indexesOfModifiedGroups: IndexSet) {
        var metaDataBlock: AVDateRangeMetadataGroup
        var metaDataItem: AVMetadataItem
        var metaString: String!
        var firstvast = 0
        
        for index in indexesOfNewGroups{
            metaDataBlock =  metadataGroups[index]
            for (metaDataItem) in metaDataBlock.items {
                metaString = metaDataItem.identifier?.rawValue
                
                if ( metaString.contains("X-AD-VAST"))
                {
                    if ( self.vastURL != metaDataItem.stringValue!)
                    {
                        self.vastURL = metaDataItem.stringValue!
                    }
                    else{
                        // Same VAST
                    }
                }
                
                if ( metaString.contains("X-AD-ID"))
                {
                    AVPlayerIntegrationWrapper.shared.setValidAdId(validAdId: metaDataItem.stringValue!)
                }
            }
        }
        
        for index in indexesOfModifiedGroups{
            
            metaDataBlock =  metadataGroups[index]
            for (metaDataItem) in metaDataBlock.items {
                
                metaString = metaDataItem.identifier?.rawValue
                if ( metaString.contains("X-AD-ID"))
                {
                    AVPlayerIntegrationWrapper.shared.setValidAdId(validAdId: metaDataItem.stringValue!)
                }
            }
        }
        AVPlayerIntegrationWrapper.shared.parseVastURL(vastURL: self.vastURL)
    }
    
    public func initialiseSSAIAdManager(mediaUrl: String, vastUrl: String, isLive: Bool) {
        self.isLive = isLive
        GenericMMWrapper.shared.genericAdDelegate = self
        GenericMMWrapper.shared.initialiseSSAIAdManager(mediaUrl: mediaUrl, vastUrl: vastUrl, isLive: isLive)
    }
    
    public func fireTrackingUrl() {
        GenericMMWrapper.shared.fireAdClickTrackingURLs()
    }
    
    public func enableSSAILogTrace()
    {
        GenericMMWrapper.shared.enableSSAILogTrace()
    }
    
    
    public func disableSSAILogTrace()
    {
        GenericMMWrapper.shared.disableSSAILogTrace()
    }
    
    public func initialiseSSAIAdManager(mediaUrl: String, isLive: Bool, pollForVast: Bool, vodResponseData: Data, clientSideTracking: Bool) {
        self.isLive = isLive
        GenericMMWrapper.shared.genericAdDelegate = self
        GenericMMWrapper.shared.initialiseSSAIAdManager(mediaUrl: mediaUrl, isLive: isLive, pollForVast: pollForVast, vodResponseData: vodResponseData, clientSideTracking: clientSideTracking)
    }
    
    public func syncEpochTime(epochTime: Int64)
    {
        GenericMMWrapper.shared.syncEpochTime (epochTime: epochTime)
    }
    
    public func parseVastURL( vastURL: String)
    {
        GenericMMWrapper.shared.parseVastURL(vastURL: vastURL)
    }
    
    public func setValidAdId( validAdId: String)
    {
        GenericMMWrapper.shared.setValidAdId(validAdId: validAdId)
    }
    
    public func stopSSAIAdManager() {
        GenericMMWrapper.shared.stopSSAIAdManager()
    }
    
    public func setMacroSubstitution(macroData dictionary: Dictionary<String, Any>){
        GenericMMWrapper.shared.setMacroSubstitution(macroData: dictionary)
    }
    //ENABLE SSAI
}
#endif

//ENABLE SSAI
#if canImport(MediaMelonNowtilustvOS)
#if os(tvOS)
public protocol MMSSAIManagerDelegate: AnyObject {
    func notifyMMSSAIAdEvents(eventName: MMSSAIAdSate, adInfo: MMSSAIAdDetails)
    func notifyMMSSAIAdEventsWithTimeline(eventName: MMSSAIAdSate, adTimeline: [MMSSAIAdDetails])
}

extension AVPlayerIntegrationWrapper: GenericAdProtocol {
    public func notifySSAIAdDetailsWithTimeline(eventName: MMSSAIAdSate, adTimeline: [MMSSAIAdDetails]) {
        self.mmssaiManagerDelegate?.notifyMMSSAIAdEventsWithTimeline(eventName: eventName, adTimeline: adTimeline)
    }
    
    public func notifySSAIAdDetails(eventName: MMSSAIAdSate, adInfo: MMSSAIAdDetails) {
        self.mmssaiManagerDelegate?.notifyMMSSAIAdEvents(eventName: eventName, adInfo: adInfo)
    }
}

extension AVPlayerIntegrationWrapper: AVPlayerItemMetadataCollectorPushDelegate {
    public func getVersion() -> String {
        return AVPlayerIntegrationWrapper.shared.sdkVersion
    }
    
    public static func getAdId(adInfo: MMSSAIAdDetails)->String{
        return (adInfo.adId)
    }
    
    public static func getAdTitle(adInfo: MMSSAIAdDetails)->String{
        return (adInfo.adTitle)
    }
    
    public static func getAdIndex(adInfo: MMSSAIAdDetails)->Int{
        return (adInfo.adIndex)
    }
    
    public static func getAdTotalAdsInPod(adInfo: MMSSAIAdDetails)->Int{
        return (adInfo.adTotalAdsInPod)
    }
    
    public static func getAdServer(adInfo: MMSSAIAdDetails)->String{
        return (adInfo.adServer)
    }
    
    public static func getAdDuration(adInfo: MMSSAIAdDetails)->Int64{
        return (adInfo.adDuration)
    }
    
    public static func getAdPosition(adInfo: MMSSAIAdDetails)->String{
        return (adInfo.position)
    }
    
    public static func getAdPlaybackTime(adInfo: MMSSAIAdDetails)->Int64{
        return (adInfo.adCurrentPlaybackTime)
    }
    
    public static func getClickThroughURL(adInfo: MMSSAIAdDetails)->String{
        for adClickEvent in adInfo.adClickEvents
        {
            let eventType =  (adClickEvent.type.rawValue)
            if eventType.contains("ClickThrough") && adClickEvent.url?.absoluteString != nil
            {
                return (adClickEvent.url?.absoluteString)!
            }
        }
        return "None"
    }
    
    public static func getClickTrackingURL(adInfo: MMSSAIAdDetails)->String{
        for adClickEvent in adInfo.adClickEvents
        {
            let eventType =  (adClickEvent.type.rawValue)
            
            if eventType.contains("ClickTracking") && adClickEvent.url?.absoluteString != nil
            {
                return (adClickEvent.url?.absoluteString)!
            }
        }
        return "None"
    }
    
    public static func setMetaDataCollector(player: AVPlayer, collector: AVPlayerItemMetadataCollector, playerItem: AVPlayerItem)
    {
        playerItem.add(collector)
        player.replaceCurrentItem(with: playerItem)
        collector.setDelegate(self.shared, queue: DispatchQueue.main)
    }
    
    public func metadataCollector(_ metadataCollector: AVPlayerItemMetadataCollector, didCollect metadataGroups: [AVDateRangeMetadataGroup], indexesOfNewGroups: IndexSet, indexesOfModifiedGroups: IndexSet) {
        var metaDataBlock: AVDateRangeMetadataGroup
        var metaDataItem: AVMetadataItem
        var metaString: String!
        var firstvast = 0
        
        for index in indexesOfNewGroups{
            metaDataBlock =  metadataGroups[index]
            for (metaDataItem) in metaDataBlock.items {
                metaString = metaDataItem.identifier?.rawValue
                
                if ( metaString.contains("X-AD-VAST"))
                {
                    if ( self.vastURL != metaDataItem.stringValue!)
                    {
                        self.vastURL = metaDataItem.stringValue!
                    }
                    else{
                        // Same VAST
                    }
                }
                
                if ( metaString.contains("X-AD-ID"))
                {
                    AVPlayerIntegrationWrapper.shared.setValidAdId(validAdId: metaDataItem.stringValue!)
                }
            }
        }
        
        for index in indexesOfModifiedGroups{
            
            metaDataBlock =  metadataGroups[index]
            for (metaDataItem) in metaDataBlock.items {
                
                metaString = metaDataItem.identifier?.rawValue
                if ( metaString.contains("X-AD-ID"))
                {
                    AVPlayerIntegrationWrapper.shared.setValidAdId(validAdId: metaDataItem.stringValue!)
                }
            }
        }
        AVPlayerIntegrationWrapper.shared.parseVastURL(vastURL: self.vastURL)
    }
    
    public func initialiseSSAIAdManager(mediaUrl: String, vastUrl: String, isLive: Bool) {
        self.isLive = isLive
        GenericMMWrapper.shared.genericAdDelegate = self
        GenericMMWrapper.shared.initialiseSSAIAdManager(mediaUrl: mediaUrl, vastUrl: vastUrl, isLive: isLive)
    }
    
    public func fireTrackingUrl() {
        GenericMMWrapper.shared.fireAdClickTrackingURLs()
    }
    
    public func enableSSAILogTrace()
    {
        GenericMMWrapper.shared.enableSSAILogTrace()
    }
    
    
    public func disableSSAILogTrace()
    {
        GenericMMWrapper.shared.disableSSAILogTrace()
    }
    
    public func initialiseSSAIAdManager(mediaUrl: String, isLive: Bool, pollForVast: Bool, vodResponseData: Data, clientSideTracking: Bool) {
        self.isLive = isLive
        GenericMMWrapper.shared.genericAdDelegate = self
        GenericMMWrapper.shared.initialiseSSAIAdManager(mediaUrl: mediaUrl, isLive: isLive, pollForVast: pollForVast, vodResponseData: vodResponseData, clientSideTracking: clientSideTracking)
    }
    
    public func syncEpochTime(epochTime: Int64)
    {
        GenericMMWrapper.shared.syncEpochTime (epochTime: epochTime)
    }
    
    public func parseVastURL( vastURL: String)
    {
        GenericMMWrapper.shared.parseVastURL(vastURL: vastURL)
    }
    
    public func setValidAdId( validAdId: String)
    {
        GenericMMWrapper.shared.setValidAdId(validAdId: validAdId)
    }
    
    public func stopSSAIAdManager() {
        GenericMMWrapper.shared.stopSSAIAdManager()
    }
    
    public func setMacroSubstitution(macroData dictionary: Dictionary<String, Any>){
        GenericMMWrapper.shared.setMacroSubstitution(macroData: dictionary)
    }
    //ENABLE SSAI
}
#endif
#endif


@objc public class AVPlayerIntegrationWrapper: NSObject { //ENABLE SSAI
    
    //MARK:- OBJECTS
    private enum CurrentPlayerState {
        case IDLE,
             PLAYING,
             PAUSED,
             STOPPED,
             ERROR
    }
    
    private enum Seek {
        case IDLE, START, COMPLETE
    }
    
    private enum CurrentBufferingState {
        case IDLE,
             BUFFER_STARTED,
             BUFFER_COMPLETED
    }
    
    private var coreSDK = ""
    private var IMASDK = ""
        
    private var sdkVersion = ""
    private var sessTerminated: Bool = false
    private var timer: Timer?
    private var timerFWAd: Timer?
    weak private var player: AVPlayer?
    weak private var playerItemObserverAdded: AVPlayerItem?
    
    private let TIME_INCREMENT = 1.0
    private var presentationInfoSet = false
    private var infoEventIdx = 0
    private var errEventIdx = 0
    private var infoEventsIdxToSkip = -1
    private var errorEventsIdxToSkip = -1
    private var durationWatchedTotal: TimeInterval = 0
    private var currentBitrate: Double = 0
    private var frameLossCnt: Int = 0
    private var isInitialBitrateReported = false;
    private var lastObservedBitrateOfContinuedSession = -1.0
    private var lastObservedDownlaodRateOfContinuedSession = -1
    private var contentURL: String?
    private var currentState = CurrentPlayerState.IDLE
    private var currentBufferState = CurrentBufferingState.IDLE
    private var lastPlaybackPos: Int64 = 0
    private var lastPlaybackPosRecordTime: Int64 = 0
    private var notificationObservors = [Any]()
    private var timeObservor: Any?
    private var playerObserved:Bool = false
    private var assetInfo: MMAssetInformation?
    private var sessionInStartedState = false
    private var loadEventTriggered = false
    private static var enableLogging = false
    private var extIsLive: Bool?
    private var seekState: Seek = Seek.IDLE
    
    //ENABLE SSAI
    
#if canImport(MediaMelonNowtilus)
    private var vastURL = ""
    private var mutex = pthread_mutex_t()
    public weak var mmssaiManagerDelegate: MMSSAIManagerDelegate?
    fileprivate var mmssaiAdManager: MMSSAIAdManager?
    fileprivate var currentAdState = MMAdState.UNKNOWN
    var isLive: Bool = false
    public weak var genericAdDelegate: GenericAdProtocol?
#endif
    
    
#if canImport(MediaMelonNowtilustvOS)
#if os(tvOS)
    private var vastURL = ""
    private var mutex = pthread_mutex_t()
    public weak var mmssaiManagerDelegate: MMSSAIManagerDelegate?
    fileprivate var mmssaiAdManager: MMSSAIAdManager?
    fileprivate var currentAdState = MMAdState.UNKNOWN
    var isLive: Bool = false
    public weak var genericAdDelegate: GenericAdProtocol?
#endif
#endif
    
    
    private enum AVPlayerPropertiesToObserve: String {
        case PlaybackRate = "rate",
             CurrentItem = "currentItem"
    }
    
    private enum AVPlayerItemPropertiesToObserve: String {
        case Duration = "duration",
             Playable = "playable",
             ItemStatus = "status",
             PresentationSize = "presentationSize",
             PlaybackBufferEmpty = "playbackBufferEmpty",
             PlaybackLikelyToKeepUp = "playbackLikelyToKeepUp",
             PlaybackBufferFull = "playbackBufferFull"
    }
    
    private static let KPlaybackSessionID = "PlaybackSessionID"
    private static let KErrorInstantTime = "ErrorInstantTime"
    private static let KPlaybackUri = "PlaybackUri"
    private static let KErrorStatusCode = "StatusCode"
    private static let KServerAddress = "ServerAddress"
    private static let KErrorDomain = "ErrorDomain"
    private static let KErrorComment = "ErrorComment"
    private static let KPlaybackPosPollingIntervalSec = 0.5
    private static let KPlaybackPosPollingIntervalMSec = 500
    private static let KMinPlaybackPosDriftForPlayingStateMSec = 400
    private static let KMinPlaybackPosDriftForPausedStateMSec = 200
    private static var appNotificationObsRegistered = false
    private var presentationDuration:CMTime?
    
    
    private override init() {
        #if os(tvOS)
        self.coreSDK = "TVOSSDK"
        #else
        self.coreSDK = "IOSSDK"
        #endif
        
        #if canImport(MediaMelonIMA)
        IMASDK = "_IMA"
        #endif
        
        #if canImport(MediaMelonIMAtvOS)
        IMASDK = "_IMA"
        #endif
        
        sdkVersion = coreSDK + IMASDK + "_AV_" + GenericMMWrapper.shared.getCoreSDKVersion() + ".3.2"
        super.init()
    }
    
    /*
     * Singleton instance of the adaptor
     */
    public static  let shared = AVPlayerIntegrationWrapper()
    
    //MARK:- METHODS
    /**
     * Gets the version of the SDK
     */
    @objc public static func getVersion() -> String! {
        return shared.sdkVersion
    }
    
    /**
     * If for some reasons, accessing the content manifest by SDK interferes with the playback. Then user can disable the manifest fetch by the SDK.
     * For example - If there is some token scheme in content URL, that makes content to be accessed only once, then user of SDK may will like to call this API.
     * So that player can fetch the manifest
     */
    @objc public static func disableManifestsFetch(disable: Bool) {
        return GenericMMWrapper.disableManifestsFetch(disable: disable)
    }
    
    /**
     * Allows user of SDK to provide information on Customer, Subscriber and Player to the SDK
     * Please note that it is sufficient to call this API only once for the lifetime of the application, and all playback sessions will reuse this information.
     *
     * Note - User may opt to call initializeAssetForPlayer instead of calling this API, and provide the registration information in its param every time as they provide the asset info. This might help ease the integration.
     *
     * This API doesnt involve any network IO, and is very light weight. So calling it multiple times is not expensive
     */
    public static func setPlayerRegistrationInformation(registrationInformation pInfo: MMRegistrationInformation?, player aPlayer: AVPlayer?) {
        if let pInfo = pInfo {
            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => setPlayerRegistrationInformation ---")
            #if os(iOS)
            pInfo.setComponentName("IOSSDK")
            #elseif os(tvOS)
            pInfo.setComponentName("tvOSSDK")
            #endif
            
            GenericMMWrapper.shared.registerForMMSDK(registrationInformation: pInfo)
        }
        if let oldPlayer = AVPlayerIntegrationWrapper.shared.player {
            AVPlayerIntegrationWrapper.shared.cleanupSession(player: oldPlayer)
        }
        if let newPlayer = aPlayer {
            AVPlayerIntegrationWrapper.shared.createSession(player: newPlayer)
        }
    }
    
    /**
     * Application may create the player with the AVAsset for every session they do the playback
     * User of API must provide the asset Information
     */
    @objc public static func initializeAssetForPlayer(assetInfo aInfo: MMAssetInformation, registrationInformation pInfo: MMRegistrationInformation?, player aPlayer: AVPlayer?, isLive: Bool) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => initializeAssetForPlayer with isLive, URL = \(aInfo.assetURL ?? "") ---")
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => SDK Version = \(AVPlayerIntegrationWrapper.shared.sdkVersion) ---")
                
        AVPlayerIntegrationWrapper.shared.extIsLive = isLive
        GenericMMWrapper.shared.reportSDKVersion(sdkVersion: AVPlayerIntegrationWrapper.shared.sdkVersion)
        AVPlayerIntegrationWrapper.setPlayerRegistrationInformation(registrationInformation: pInfo, player:aPlayer)
        AVPlayerIntegrationWrapper.changeAssetForPlayer(assetInfo: aInfo, player: aPlayer)
                
        GenericMMWrapper.shared.reportDeviceCapabilities();
    }
    
    @objc public static func initializeAssetForPlayer(assetInfo aInfo: MMAssetInformation, registrationInformation pInfo: MMRegistrationInformation?, player aPlayer: AVPlayer?) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => initializeAssetForPlayer without isLive, URL = \(aInfo.assetURL ?? "") ---")
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => SDK Version = \(AVPlayerIntegrationWrapper.shared.sdkVersion) ---")
                
        GenericMMWrapper.shared.reportSDKVersion(sdkVersion: AVPlayerIntegrationWrapper.shared.sdkVersion)
        AVPlayerIntegrationWrapper.setPlayerRegistrationInformation(registrationInformation: pInfo, player:aPlayer)
        AVPlayerIntegrationWrapper.changeAssetForPlayer(assetInfo: aInfo, player: aPlayer)
        
        GenericMMWrapper.shared.reportDeviceCapabilities();
    }
    
    /**
     * Whenever the asset with the player is changed, user of the API may call this API
     * Please note either changeAssetForPlayer or initializeAssetForPlayer should be called
     */
    public static func changeAssetForPlayer(assetInfo aInfo: MMAssetInformation, player aPlayer: AVPlayer?) {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => changeAssetForPlayer, URL = \(aInfo.assetURL ?? "") ---")
        AVPlayerIntegrationWrapper.shared.assetInfo = aInfo
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => cleanupCurrItem from changeAssetForPlayer ---")
        AVPlayerIntegrationWrapper.shared.cleanupCurrItem();
        
        if let newPlayer = aPlayer {
            if let oldPlayer = AVPlayerIntegrationWrapper.shared.player {
                if oldPlayer != newPlayer {
                    AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => changeAssetForPlayer New Player ---")
                    AVPlayerIntegrationWrapper.shared.cleanupSession(player: oldPlayer)
                    AVPlayerIntegrationWrapper.shared.player = nil;
                    AVPlayerIntegrationWrapper.shared.createSession(player: newPlayer)
                }
                
                if let playerItem = newPlayer.currentItem {
                    AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => Calling initSession from changeAssetForPlayer, True ---")
                    AVPlayerIntegrationWrapper.shared.initSession(player: newPlayer, playerItem: playerItem , deep: true)
                }
            }
        }
    }
    
    /**
     * The below API is for Just updating the AssetInfo incase of playlist mode in which our SDK automatically detects the item change and starts a new session.
     */
    public static func updateAssetInformation(assetInfo aInfo: MMAssetInformation) {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => updateAssetInformation ---")
        AVPlayerIntegrationWrapper.shared.assetInfo = aInfo
    }
    
    /**
     * Once the player is done with the playback session, then application should call this API to clean up observors set with the player and the player's current item
     */
    @objc public static func cleanUp() {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => cleanUp ---")
        AVPlayerIntegrationWrapper.shared.cleanupInstance()
    }
    
    /**
     * Application may update the subscriber information once it is set via MMRegistrationInformation
     */
    public static func updateSubscriber(subscriberId: String!, subscriberType: String!, subscriberMetadata: String!) {
        GenericMMWrapper.updateSubscriber(subscriberId: subscriberId, subscriberType: subscriberType, subscriberMetadata: subscriberMetadata)
    }
    
    /**
     * Application may report the custom metadata associated with the content using this API.
     * Application can set it as a part of MMAVAssetInformation before the start of playback, and
     * can use this API to set metadata during the course of the playback.
     */
    public func reportCustomMetadata(key: String!, value: String!) {
        GenericMMWrapper.shared.reportCustomMetadata(key: key, value: value)
    }
    
    
    /**
     * Application may report the custom metadata associated with the content using this API.
     * Application can set it as a part of MMAVAssetInformation before the start of playback, and
     * can use this API to set metadata during the course of the playback.
     */
    public func reportVideoQuality(videoQuality: String) {
        GenericMMWrapper.shared.reportVideoQuality(videoQuality: videoQuality);
    }
    
    public func reportDeviceMarketingName(deviceMarketingName: String) {
        GenericMMWrapper.shared.reportDeviceMarketingName(deviceMarketingName: deviceMarketingName);
    }
    
    /**
     * Application may report the custom metadata associated with the content using this API.
     * Application can set it as a part of MMAVAssetInformation before the start of playback, and
     * can use this API to set metadata during the course of the playback.
     */
    public func reportAppData(appName: String, appVersion: String) {
        GenericMMWrapper.shared.reportAppData(appName: appName, appVersion: appVersion)
    }
    
    /**
     * Used for debugging purposes, to enable the log trace
     */
    public func enableLogTrace(logStTrace: Bool) {
        AVPlayerIntegrationWrapper.enableLogging = logStTrace
        GenericMMWrapper.shared.enableLogTrace(logStTrace: logStTrace)
    }
    
    public func reportExperimentName(experimentName: String?) {
        GenericMMWrapper.shared.reportExperimentName(experimentName: experimentName)
    }
    
    public func reportSubPropertyID(subPropertyId: String?) {
        GenericMMWrapper.shared.reportSubPropertyID(subPropertyId: subPropertyId)
    }
    
    public func reportViewSessionID(viewSessionId: String?) {
        GenericMMWrapper.shared.reportViewSessionID(viewSessionId: viewSessionId)
    }
    
    public func reportBasePlayerInfo(basePlayerName: String?, basePlayerVersion: String?) {
        GenericMMWrapper.shared.reportBasePlayerInfo(basePlayerName: basePlayerName, basePlayerVersion: basePlayerVersion)
    }
    
    /**
     * If application wants to send application specific error information to SDK, the application can use this API.
     * Note - SDK internally takes care of notifying the error messages provided to it by AVFoundation framwork
     */
    public func reportError(error: String, playbackPosMilliSec: Int) {
        GenericMMWrapper.shared.reportError(error: error, playbackPosMilliSec: playbackPosMilliSec)
    }
    
    public static func reportMetricValue(metricToOverride: MMOverridableMetrics, value: String!) {
        switch metricToOverride {
        case MMOverridableMetrics.CDN:
            GenericMMWrapper.reportMetricValue(metricToOverride: MMOverridableMetric.ServerAddress, value: value)
        default:
            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => Only CDN metric is overridable as of now ---")
        }
    }
    
    private static func logDebugStatement(_ logStatement: String) {
        if(AVPlayerIntegrationWrapper.enableLogging) {
            print(logStatement)
        }
    }
    
    @objc func handleAVPlayerAccess(notification: Notification) {
        
        guard let playerItem = notification.object as? AVPlayerItem,
              let lastEvent = playerItem.accessLog()?.events.last else {
            return
        }
        guard let indicatedStream = lastEvent.uri else { return }
        guard let contentURL = self.contentURL, let streamUrl = URL(string: contentURL) else { return }
        if let url = URL(string: indicatedStream) {
            if url.host != streamUrl.host {
                AVPlayerIntegrationWrapper.reportMetricValue(metricToOverride: .CDN, value: url.host)
            }
        }
        // Use bitrate to determine bandwidth decrease or increase.
    }
    
    @objc func reportMediaSelectionChange()
    {
        var subTitleTrack = "None"
        var audioTrack = "None"
        var isSubtitleActive = false
        var isVDSActive = false
        
        if let playerItem = player?.currentItem,
           let group = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {
            let selectedOption = playerItem.currentMediaSelection.selectedMediaOption(in: group)
            
            if let selectedSubtitle = selectedOption?.displayName {
                subTitleTrack = selectedSubtitle
                isSubtitleActive = true
            }
        }
        
        
        if let playerItem = player?.currentItem,
           let group = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.audible) {
            let selectedOption = playerItem.currentMediaSelection.selectedMediaOption(in: group)
            
            if let selectedAudio = selectedOption?.displayName {
                audioTrack = selectedAudio
                
                if audioTrack.lowercased().contains("commentary") {
                    isVDSActive = true
                }
            }
        }
        
        if let playerItem = player?.currentItem,
           let group = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.visual) {
            let selectedOption = playerItem.currentMediaSelection.selectedMediaOption(in: group)
            
            if let selectedVideo = selectedOption?.displayName {
            }
        }
        
        GenericMMWrapper.shared.reportMediaTrackInfo(isSubtitleActive: isSubtitleActive, subtitleTrack: subTitleTrack, audioTrack: audioTrack, isVDSActive: isVDSActive)
    }
    
    // Observer for subtitle
    @objc func handleMediaSelectionChange(_ notification: Notification) {
        self.reportMediaSelectionChange()
    }
    
    func reportNetworkType(connInfo: MMConnectionInfo) {
        GenericMMWrapper.shared.reportNetworkType(connInfo: connInfo)
    }
    
    @objc private func timeoutOccurred() {
        guard self.player != nil else {
            return
        }
        let pbpos = getPlaybackPosition()
        GenericMMWrapper.shared.updatePlaybackPosition(currentPosition: pbpos)
    }
    
    private func getPlaybackPosition() -> Int {
        guard let player = self.player else{
            return 0
        }
        let time = player.currentTime()
        if(time.timescale > 0){
            return Int((time.value)/(Int64)(time.timescale)) * 1000;
        }else{ //Avoid dividing by 0 , -ve should not be expected
            return 0
        }
    }
    
    private func cleanupInstance() {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => cleanupCurrItem from cleanupInstance ---")
        self.cleanupCurrItem()
        guard let player = player else {
            return
        }
        
        self.cleanupSession(player: player)
    }
    
    private func cleanupCurrItem() {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => cleanupCurrItem ---")
        guard let player = self.player else{
            return
        }
        guard let playerItem = player.currentItem else {
            return
        }
        self.resetSession(item: playerItem)
    }
    
    private func playbackDidReachEnd(notification noti: Notification) {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => playbackDidReachEnd ---")
        self.reportStoppedState()
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => cleanupCurrItem from playbackDidReachEnd ---")
        self.cleanupCurrItem()
    }
    
    private func playbackFailedToPlayTillEnd(notification noti: Notification) {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => playbackFailedToPlayTillEnd ---")
        GenericMMWrapper.shared.reportError(error: noti.description, playbackPosMilliSec: -1)
        self.currentState = .ERROR
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => cleanupCurrItem from playbackFailedToPlayTillEnd ---")
        self.cleanupCurrItem()
    }
    
    private func handleErrorWithMessage(message: String?, error: Error? = nil) {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => handleErrorWithMessage. Error occurred with message: \(String(describing: message)), error: \(String(describing: error)).")
        GenericMMWrapper.shared.reportError(error: String(describing: error), playbackPosMilliSec: getPlaybackPosition())
    }
    
    private func reset() {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => reset ---")
        self.lastPlaybackPos = 0
        self.lastPlaybackPosRecordTime = 0
        self.sessionInStartedState = false
        self.presentationInfoSet = false
        self.infoEventIdx = 0
        self.errEventIdx = 0
        self.infoEventsIdxToSkip = -1
        self.errorEventsIdxToSkip = -1
        self.lastObservedBitrateOfContinuedSession = -1.0
        self.lastObservedDownlaodRateOfContinuedSession = -1
        self.durationWatchedTotal = 0
        self.currentBitrate = 0
        self.frameLossCnt = 0
        self.isInitialBitrateReported = false
        self.contentURL = nil
        self.currentState = CurrentPlayerState.IDLE
        self.loadEventTriggered = false
        
        if AVPlayerIntegrationWrapper.appNotificationObsRegistered == false{
            AVPlayerIntegrationWrapper.appNotificationObsRegistered = true
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: nil) { (notification) in
                    MMReachabilityManager.shared.stopMonitoring()
                }
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: nil) { (notification) in
                    MMReachabilityManager.shared.startMonitoring()
                }
            MMReachabilityManager.shared.startMonitoring()
        }
    }
    
    private func createSession(player: AVPlayer) {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => createSession ---")
        self.player = player
        self.addPlayerObservors();
        self.timer = nil
    }
    
    private func initSession(player: AVPlayer, playerItem: AVPlayerItem, deep: Bool) {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => In initSession, Deep = \(deep) ---")
        var infoEventsIdxToSkipCache = -1
        var errorEventsIdxToSkipCache = -1
        
        if (self.infoEventsIdxToSkip != -1){
            infoEventsIdxToSkipCache = self.infoEventsIdxToSkip
        }
        if (self.errorEventsIdxToSkip != -1){
            errorEventsIdxToSkipCache = self.errorEventsIdxToSkip
        }
        
        if(deep){
            self.reset()
        }
        
        self.infoEventsIdxToSkip = infoEventsIdxToSkipCache
        self.errorEventsIdxToSkip = errorEventsIdxToSkipCache
        
        guard let assetInfo = self.assetInfo else {
            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => !!! Error - assetInfo not set !!! ---")
            return
        }
        
        self.sessTerminated = false;
        contentURL = assetInfo.assetURL
        
        if(deep) {
            GenericMMWrapper.shared.initialiseSession(registrationUri: "https://register.mediamelon.com/mm-apis/register/", assetInformation: assetInfo)
            for (key, value) in assetInfo.customKVPs {
                AVPlayerIntegrationWrapper.shared.reportCustomMetadata(key: key, value: value)
            }
            if( self.loadEventTriggered == false) {
                GenericMMWrapper.shared.reportUserInitiatedPlayback()
                self.loadEventTriggered = true
            }
        } else {
            for (key, value) in assetInfo.customKVPs {
                AVPlayerIntegrationWrapper.shared.reportCustomMetadata(key: key, value: value)
            }
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: self.TIME_INCREMENT, target:self, selector:#selector(AVPlayerIntegrationWrapper.timeoutOccurred), userInfo: nil, repeats: true)
        
        playerItem.addObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.Duration.rawValue, options: [.new], context: &AVFoundationPlayerViewControllerKVOContext)
        playerItem.addObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.Playable.rawValue, options: [.new], context: &AVFoundationPlayerViewControllerKVOContext)
        playerItem.addObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.ItemStatus.rawValue, options: [.new, .initial], context: &AVFoundationPlayerViewControllerKVOContext)
        playerItem.addObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.PresentationSize.rawValue, options: [.new, .initial], context: &AVFoundationPlayerViewControllerKVOContext)
        playerItem.addObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.PlaybackBufferEmpty.rawValue, options: [.new, .initial], context: &AVFoundationPlayerViewControllerKVOContext)
        playerItem.addObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.PlaybackLikelyToKeepUp.rawValue, options: [.new, .initial], context: &AVFoundationPlayerViewControllerKVOContext)
        playerItem.addObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.PlaybackBufferFull.rawValue, options: [.new, .initial], context: &AVFoundationPlayerViewControllerKVOContext)
        
        var observor = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: playerItem, queue: nil, using: {  (not) in  self.playbackDidReachEnd(notification:not)})
        self.notificationObservors.append(observor)
        observor = NotificationCenter.default.addObserver(forName: AVPlayerItem.failedToPlayToEndTimeNotification, object: playerItem, queue: nil, using: {  (not) in  self.playbackFailedToPlayTillEnd(notification:not)})
        self.notificationObservors.append(observor)
        observor = NotificationCenter.default.addObserver(forName: AVPlayerItem.newAccessLogEntryNotification, object: playerItem, queue: nil, using: {  (not) in  self.newAccessLogEntryRecvd(notification:not)})
        self.notificationObservors.append(observor)
        observor = NotificationCenter.default.addObserver(forName: AVPlayerItem.newErrorLogEntryNotification, object: playerItem, queue: nil, using: {  (not) in  self.newErrorLogEntryRecvd(notification:not)})
        self.notificationObservors.append(observor)
        
        self.reportMediaSelectionChange()
        
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self,selector: #selector(self.handleMediaSelectionChange(_:)),name: AVPlayerItem.mediaSelectionDidChangeNotification, object: player.currentItem)
        }
        
        self.playerItemObserverAdded = playerItem
        if (self.infoEventsIdxToSkip >= 0 || self.errorEventsIdxToSkip >= 0) {
            self.processEventsRegister()
            self.processErrorEventsRegister()
            self.infoEventsIdxToSkip = -1
            self.errorEventsIdxToSkip = -1
        }
        
        let url = (playerItem.asset as? AVURLAsset)?.url
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => Initializing for \(String(describing: url)) ---")
    }
    
    private func resetSession(item: AVPlayerItem?) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => resetSession ---")
        guard let playerItem = item else {
            return;
        }
        
        guard let observerAddedPlayerItem = self.playerItemObserverAdded else {
            return
        }
        
        if (observerAddedPlayerItem == item) {
            for item in self.notificationObservors {
                NotificationCenter.default.removeObserver(item);
            }
            self.playerItemObserverAdded = nil
            self.notificationObservors.removeAll();
            
            playerItem.removeObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.Duration.rawValue, context: &AVFoundationPlayerViewControllerKVOContext);
            playerItem.removeObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.Playable.rawValue, context: &AVFoundationPlayerViewControllerKVOContext);
            playerItem.removeObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.ItemStatus.rawValue, context: &AVFoundationPlayerViewControllerKVOContext);
            playerItem.removeObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.PresentationSize.rawValue, context: &AVFoundationPlayerViewControllerKVOContext);
            playerItem.removeObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.PlaybackBufferEmpty.rawValue, context: &AVFoundationPlayerViewControllerKVOContext);
            playerItem.removeObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.PlaybackLikelyToKeepUp.rawValue, context: &AVFoundationPlayerViewControllerKVOContext);
            playerItem.removeObserver(self, forKeyPath: AVPlayerItemPropertiesToObserve.PlaybackBufferFull.rawValue, context: &AVFoundationPlayerViewControllerKVOContext);
            
            if let tmr = self.timer {
                tmr.invalidate();
            }
            
            self.reportStoppedState()
            self.sessTerminated = true;
            self.seekState = .IDLE
            let url = (playerItem.asset as? AVURLAsset)?.url
            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => resetSession \(String(describing: url)) ---")
        }
    }
    
    private func cleanupSession(player: AVPlayer?) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => cleanupSession ---")
        if let player = player {
            self.removePlayerObservors(player: player);
        }
        self.player = nil
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => removeSession ---")
    }
    
    private func continueStoppedSession() {
        guard let player = self.player else{
            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => !!! Error - continueStoppedSession failed, player not avl ---")
            return
        }
        guard let playerItem = self.player?.currentItem else {
            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => !!! Error - continueStoppedSession failed, playerItem not avl ---")
            return
        }
        self.sessTerminated = false;
        //Lets save the player events that were sent earlier. The ones those were pushed earlier, will reappear after deep init of session.
        self.infoEventsIdxToSkip = infoEventIdx
        self.errorEventsIdxToSkip = errEventIdx
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => Calling initSession from continueStoppedSession, True ---")
        self.initSession(player: player, playerItem: playerItem, deep: true)
        self.setPresentationInformationForContent()
    }
    
    private func reportStoppedState() {
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => reportStoppedState ---")
        if(self.currentState != .IDLE && self.currentState != .STOPPED) {
            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => reportStoppedState Entered ---")
            if let player = self.player {
                let time = player.currentTime();
                if(time.timescale > 0){
                    GenericMMWrapper.shared.updatePlaybackPosition(currentPosition: Int((time.value)/(Int64)(time.timescale)) * 1000)
                }
            }
            GenericMMWrapper.shared.reportPlayerState(playerState: MMPlayerState.STOPPED)
            self.currentState = .STOPPED
        }
    }
    
    private func processDuration(change: [NSKeyValueChangeKey : Any]?) {
        guard self.player != nil else {
            return;
        }
        
        let newDuration: CMTime
        if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? NSValue {
            newDuration = newDurationAsValue.timeValue
        }
        else {
            newDuration = CMTime.zero
        }
        
        self.presentationDuration = newDuration
        self.setPresentationInformationForContent()
    }
    
    private func processDurationFromPlayerItem() {
        guard self.player != nil else {
            return;
        }
        
        if let item = self.player?.currentItem {
            self.presentationDuration = item.duration
            self.setPresentationInformationForContent()
        }
    }
    
    private func setPresentationInformationForContent() {
        guard let contentDuration = presentationDuration else{
            return
        }
        
        if !self.presentationInfoSet {
            let presentationInfo = MMPresentationInfo()
            
            let hasValidDuration = contentDuration.isNumeric && contentDuration.value != 0
            if(hasValidDuration){
                let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(contentDuration) : 0.0
                AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => Duration of content is \(String(describing: newDurationSeconds * 1000)) ---")
                let duration  = newDurationSeconds * 1000
                presentationInfo.duration = Int(duration)
                presentationInfo.isLive = false
            } else {
                presentationInfo.duration = Int(-1)
                presentationInfo.isLive = true
            }
            
            // if the user is setting is explicitly then consider that value.
            if let extIsLive {
                presentationInfo.isLive = extIsLive
            }

            GenericMMWrapper.shared.setPresentationInformation(presentationInfo: presentationInfo)
            self.presentationInfoSet = true
        }
    }
    
    private func processPlaybackRate(_ rate:Float){
        switch rate {
        case 0.0:
            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => LATENCY: - Playback rate 0 ---")
            if self.currentState != .PAUSED{
                GenericMMWrapper.shared.reportPlayerState(playerState: MMPlayerState.PAUSED);
                self.currentState = .PAUSED
            }
            
        default:
            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => LATENCY: - Playback rate \(rate) ---")
            break
        }
    }
    
    private func playbackFailed(){
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => playbackFailed ---")
        var currContent = "Content Not Set";
        if let contentURL = self.contentURL {
            currContent = contentURL;
        }
        GenericMMWrapper.shared.reportError(error: String("Playback of \(currContent) Failed"), playbackPosMilliSec: self.getPlaybackPosition())
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => cleanupCurrItem from playbackFailed ---")
        self.cleanupCurrItem();
    }
    
    //commenting this part of code to give the initialization access to customer. This is causing multiple sessions = EVBS issue
    //    private func processCurrentItemChange(old oldItem:AVPlayerItem?, new newItem:AVPlayerItem?){
    //        guard let player = self.player else{
    //            return
    //        }
    //        AVPlayerIntegrationWrapper.logDebugStatement("--Process current item changed with the player--")
    //        // Player Item has changed (asset being played)
    //        if let oldItem = oldItem{
    //            self.resetSession(item: oldItem)
    //        }
    //
    //        if let newItem = newItem{
    //            self.initSession(player: player, playerItem: newItem, deep: true)
    //        }
    //    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &AVFoundationPlayerViewControllerKVOContext || context == &AVFoundationPlayerViewControllerKVOContextPlayer else {
            super.observeValue(forKeyPath:keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == AVPlayerItemPropertiesToObserve.Duration.rawValue {
            self.processDuration(change: change)
        }
        else if keyPath == AVPlayerItemPropertiesToObserve.ItemStatus.rawValue {
            let newStatus: AVPlayerItem.Status
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
                if newStatus == .failed{
                    self.playbackFailed();
                }
            }
            else {
                newStatus = .unknown
            }
            
            switch newStatus {
            case .readyToPlay:
                self.processDurationFromPlayerItem()
            default:
                break
            }
        }
        else if keyPath == AVPlayerItemPropertiesToObserve.PlaybackBufferEmpty.rawValue {
            if(currentBufferState == CurrentBufferingState.IDLE || currentBufferState == CurrentBufferingState.BUFFER_COMPLETED) {
                GenericMMWrapper.shared.reportBufferingStarted()
                currentBufferState = CurrentBufferingState.BUFFER_STARTED;
            }
        }
        else if (keyPath == AVPlayerItemPropertiesToObserve.PlaybackLikelyToKeepUp.rawValue || keyPath == AVPlayerItemPropertiesToObserve.PlaybackBufferFull.rawValue) {
            //Change to handle the event: kCMTimebaseNotification_EffectiveRateChanged for buffering completion
        }
        else if keyPath == AVPlayerItemPropertiesToObserve.PresentationSize.rawValue {
            if let presentationSz = change?[NSKeyValueChangeKey.newKey]{
                let pSz = presentationSz as! CGSize
                GenericMMWrapper.shared.reportPresentationSize(width: Int(pSz.width), height: Int(pSz.height))
            }
        }
        else if keyPath ==  AVPlayerPropertiesToObserve.PlaybackRate.rawValue{
            self.processPlaybackRate((object! as AnyObject).rate);
        }
        else if keyPath == AVPlayerPropertiesToObserve.CurrentItem.rawValue{
            // Commenting the below code to avoid multiple session creations in the case of Playlist Modes
            //            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => Current Item Change Event Listener ---")
            //            let newItem = change?[NSKeyValueChangeKey.newKey] as? AVPlayerItem
            //            let oldItem = change?[NSKeyValueChangeKey.oldKey] as? AVPlayerItem
            //            self.processCurrentItemChange(old:oldItem, new:newItem);
        }
    }
    
    private func addPlayerObservors(){
        guard let player = self.player else{
            return
        }
        
        player.addObserver(self, forKeyPath: AVPlayerPropertiesToObserve.PlaybackRate.rawValue, options: [.new, .initial], context: &AVFoundationPlayerViewControllerKVOContextPlayer)
        player.addObserver(self, forKeyPath: AVPlayerPropertiesToObserve.CurrentItem.rawValue, options: [.new, .old], context: &AVFoundationPlayerViewControllerKVOContextPlayer)
        NotificationCenter.default.addObserver(self, selector: #selector(AVPlayerIntegrationWrapper.handleAVPlayerAccess(notification:)), name: NSNotification.Name.AVPlayerItemNewAccessLogEntry,
                                               object: nil)
        self.startSeekWatchdogAndPlaybackPositionTracker()
        self.playerObserved = true
    }
    
    private func removePlayerObservors(player:AVPlayer){
        if(self.playerObserved == true){
            if let timeObservor = self.timeObservor{
                player.removeTimeObserver(timeObservor)
            }
            self.timeObservor = nil
            player.removeObserver(self, forKeyPath: AVPlayerPropertiesToObserve.PlaybackRate.rawValue);
            player.removeObserver(self, forKeyPath: AVPlayerPropertiesToObserve.CurrentItem.rawValue);
            self.playerObserved = false;
        }
    }
    
    
    private func processEventsRegister(){
        guard let player = self.player else{
            return
        }
        
        guard let playerItem = player.currentItem else{
            return
        }
        
        guard let observerAddedPlayerItem = self.playerItemObserverAdded else {
            return
        }
        
        if (observerAddedPlayerItem == playerItem) {
            if let evtCount = playerItem.accessLog()?.events.count {
                AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => Total events \(String(describing: evtCount)) ---")
                if (self.infoEventIdx > evtCount) {
                    self.errEventIdx = 0
                    self.infoEventIdx = 0
                    self.infoEventsIdxToSkip = -1
                    self.errorEventsIdxToSkip = -1
                }
                for i in stride(from: self.infoEventIdx, to: evtCount, by: 1) {
                    let accessEvt = playerItem.accessLog()?.events[i]
                    
                    if(self.infoEventsIdxToSkip >= self.infoEventIdx){ //We are deliberately letting download rate be passed in replay of prev session. Because, it may not be set again on replay ...
                        if let indicatedBitrate = accessEvt?.indicatedBitrate{
                            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => Skipping Event, indicatedBitrate \(indicatedBitrate) ---")
                            if  indicatedBitrate > 0.0{
                                self.lastObservedBitrateOfContinuedSession = indicatedBitrate
                            }
                        }
                        
                        if let obsBitrate = accessEvt?.observedBitrate{
                            if obsBitrate.isNormal{
                                self.lastObservedDownlaodRateOfContinuedSession = Int(obsBitrate)
                            }
                        }
                        
                        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => Skipping Event, Pending \(self.infoEventsIdxToSkip - self.infoEventIdx) ---")
                        self.infoEventIdx += 1;
                        continue
                    }
                    
                    if self.lastObservedBitrateOfContinuedSession > 0 {
                        self.currentBitrate = self.lastObservedBitrateOfContinuedSession
                        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => ABRSWITCH: !isInitialBitrateReported \(currentBitrate) => \(currentBitrate) ---")
                        GenericMMWrapper.shared.reportABRSwitch(prevBitrate: Int(currentBitrate), newBitrate: Int(currentBitrate))
                        self.isInitialBitrateReported = true
                        self.lastObservedBitrateOfContinuedSession = -1.0
                    }
                    
                    if self.lastObservedDownlaodRateOfContinuedSession > 0 {
                        GenericMMWrapper.shared.reportDownloadRate(downloadRate: self.lastObservedDownlaodRateOfContinuedSession)
                        self.lastObservedDownlaodRateOfContinuedSession = -1
                    }
                    
                    if let obsBitrate = accessEvt?.observedBitrate{
                        if obsBitrate.isNormal{
                            GenericMMWrapper.shared.reportDownloadRate(downloadRate: Int(obsBitrate))
                        }
                    }
                    
                    if let indicatedBitrate = accessEvt?.indicatedBitrate{
                        if indicatedBitrate > 0.0{
                            if self.currentBitrate == 0{
                                self.currentBitrate = indicatedBitrate
                            }
                            
                            if(self.isInitialBitrateReported == false){
                                self.isInitialBitrateReported = true
                                AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => ABRSWITCH: !isInitialBitrateReported \(self.currentBitrate) => \(self.currentBitrate) ---")
                                GenericMMWrapper.shared.reportABRSwitch(prevBitrate: Int(currentBitrate), newBitrate: Int(currentBitrate))
                            }else{
                                AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => ABRSWITCH: \(self.currentBitrate) => \(indicatedBitrate) ---")
                                if self.currentBitrate != indicatedBitrate{
                                    GenericMMWrapper.shared.reportABRSwitch(prevBitrate: Int(currentBitrate), newBitrate: Int(indicatedBitrate))
                                }
                            }
                            self.currentBitrate = indicatedBitrate
                        }
                    }
                    
                    if let droppedFrames = accessEvt?.numberOfDroppedVideoFrames{
                        if droppedFrames > self.frameLossCnt{
                            GenericMMWrapper.shared.reportFrameLoss(lossCnt: (droppedFrames-frameLossCnt))
                            self.frameLossCnt = droppedFrames
                        }
                    }
                    self.infoEventIdx += 1;
                }
            }
            
            if self.lastObservedBitrateOfContinuedSession > 0 {
                self.currentBitrate = lastObservedBitrateOfContinuedSession
                AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => ABRSWITCH: !isInitialBitrateReported \(currentBitrate) => \(currentBitrate) ---")
                GenericMMWrapper.shared.reportABRSwitch(prevBitrate: Int(currentBitrate), newBitrate: Int(currentBitrate))
                self.isInitialBitrateReported = true
                self.lastObservedBitrateOfContinuedSession = -1.0
            }
            
            if self.lastObservedDownlaodRateOfContinuedSession > 0 {
                GenericMMWrapper.shared.reportDownloadRate(downloadRate: lastObservedDownlaodRateOfContinuedSession)
                self.lastObservedDownlaodRateOfContinuedSession = -1
            }
        }
    }
    
    private func newAccessLogEntryRecvd(notification noti:Notification){
        self.processEventsRegister();
    }
    
    private func processErrorEventsRegister() {
        guard let player = self.player else{
            return
        }
        
        guard let playerItem = player.currentItem else{
            return
        }
        
        guard let observerAddedPlayerItem = self.playerItemObserverAdded else {
            return
        }
        
        if (observerAddedPlayerItem == playerItem) {
            if let errEvtCount = playerItem.errorLog()?.events.count {
                AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => Total Err events \(String(describing: errEvtCount)) ---")
                var kvpsForErr:[String] = []
                if (self.errEventIdx > errEvtCount) {
                    self.errEventIdx = 0
                    self.infoEventIdx = 0
                    self.infoEventsIdxToSkip = -1
                    self.errorEventsIdxToSkip = -1
                }
                for i in stride(from: self.errEventIdx, to: errEvtCount, by: 1) {
                    
                    if(self.errorEventsIdxToSkip >= self.errEventIdx){ //We are deliberately letting download rate be
                        
                        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => Skipping ERR Event, Pending \(self.errorEventsIdxToSkip - self.errEventIdx) ---")
                        self.errEventIdx += 1;
                        continue
                    }
                    
                    let errEvt = playerItem.errorLog()?.events[i]
                    if let sessID = errEvt?.playbackSessionID {
                        kvpsForErr.append(AVPlayerIntegrationWrapper.KPlaybackSessionID + "=" + sessID)
                    }
                    
                    if let time = errEvt?.date {
                        kvpsForErr.append(AVPlayerIntegrationWrapper.KErrorInstantTime + "=" + time.description)
                    }
                    
                    if let uri = errEvt?.uri {
                        kvpsForErr.append(AVPlayerIntegrationWrapper.KPlaybackUri + "=" + uri)
                    }
                    
                    if let statusCode = errEvt?.errorStatusCode {
                        kvpsForErr.append(AVPlayerIntegrationWrapper.KErrorStatusCode + "=" + String(statusCode))
                    }
                    
                    if let serverAddr = errEvt?.serverAddress {
                        kvpsForErr.append(AVPlayerIntegrationWrapper.KServerAddress + "=" + String(serverAddr))
                    }
                    
                    if let errDomain = errEvt?.errorDomain {
                        kvpsForErr.append(AVPlayerIntegrationWrapper.KErrorDomain + "=" + errDomain)
                    }
                    
                    if let errComment = errEvt?.errorComment {
                        kvpsForErr.append(AVPlayerIntegrationWrapper.KErrorComment + "=" + errComment)
                    }
                    self.errEventIdx += 1
                }
                
                if kvpsForErr.count > 0 {
                    //Lets not distinguish errors, filterning can better be handled in backend
                    //Session termination can be handled via player notifications when it gives up
                    let errString  = kvpsForErr.joined(separator: ":")
                    GenericMMWrapper.shared.reportError(error: errString, playbackPosMilliSec: getPlaybackPosition())
                }
            }
        }
    }
    
    private func newErrorLogEntryRecvd(notification noti: Notification) {
        self.processErrorEventsRegister()
    }
    
    private static func isPossibleSeek(currpos: Int64, lastPos: Int64, currentRecordTime: Int64, lastRecInstant:Int64) -> Bool {
        if lastRecInstant < 0 || lastPos<0 {
            return false
        }
        let posDiff = abs(currpos - lastPos)
        let wallclockTimeDiff = currentRecordTime - lastRecInstant
        let drift = Int(abs(wallclockTimeDiff - posDiff))
        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => tick isPossibleSeek: playDelta [\(posDiff) msec] wallclkDelta [\(wallclockTimeDiff) msec] drift [\(drift) msec] ---");
    
        if drift > AVPlayerIntegrationWrapper.KPlaybackPosPollingIntervalMSec {
            return true
        }
        return false
    }
    
    private func startSeekWatchdogAndPlaybackPositionTracker() {
        guard let player = self.player else {
            return
        }
        
        self.timeObservor = player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(AVPlayerIntegrationWrapper.KPlaybackPosPollingIntervalSec, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil){ [weak self] time in
            
            
            guard let player = self?.player else {
                return
            }
            
            guard let playerItem = player.currentItem else {
                return
            }
            
            let currentPlaybackPos = Int64(CMTimeGetSeconds(time) * 1000);
            let currentRecordTime = Int64(CFAbsoluteTimeGetCurrent() * 1000)
            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => tick Periodic Check -- pos=\(currentPlaybackPos) at=\(currentRecordTime) ---")
            if let timebase = playerItem.timebase {
                let observedRate = CMTimebaseGetRate(timebase)
                if observedRate > 0 {
                    AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => tick observed rate \(observedRate) player rate \(player.rate) ---")
                    if player.rate != 0 && currentPlaybackPos > 100{ //Atleast some playback is there
                
                        if(self?.currentBufferState == CurrentBufferingState.BUFFER_STARTED) {
                            GenericMMWrapper.shared.reportBufferingCompleted()
                            self?.currentBufferState = CurrentBufferingState.BUFFER_COMPLETED
                        }
                        
                        if self?.seekState == .START {
                            self?.seekState = .COMPLETE
                            GenericMMWrapper.shared.reportPlayerSeekCompleted(seekEndPos: Int(currentPlaybackPos))
                        }
                        
                        //ENABLE IMA
//                        var adPlaying = MMIMAAdManager.sharedManager.isAdPlaying_;
                        // for IMA
                        if (self?.currentState == .PAUSED || self?.currentState == .IDLE) {
                            AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => tick LATENCY: Report PLAYING ---")
                            self?.timeoutOccurred()
                            GenericMMWrapper.shared.reportPlayerState(playerState: MMPlayerState.PLAYING);
                            self?.currentState = .PLAYING
                            if(self?.sessionInStartedState == false){
                                self?.sessionInStartedState = true;
                                self?.lastPlaybackPos = currentPlaybackPos
                                self?.lastPlaybackPosRecordTime = currentRecordTime
                            }
                        }
                    }
                    
                    if (self?.sessTerminated == true) {
                        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => tick Forcing restart of session via Play .., Replay Session] ---")
                        self?.continueStoppedSession()
                        if( self?.loadEventTriggered == false) {
                            GenericMMWrapper.shared.reportUserInitiatedPlayback()
                            self?.loadEventTriggered = true
                        }
                    }
                }
                
                guard let lastPlaybackPos = self?.lastPlaybackPos else {
                    return;
                }
                
                guard let lastPlaybackPosRecordTime = self?.lastPlaybackPosRecordTime else {
                    return;
                }
                
                if(self?.sessionInStartedState == true) {
                    if ((player.rate  == 0  && abs(lastPlaybackPos - currentPlaybackPos) > AVPlayerIntegrationWrapper.KMinPlaybackPosDriftForPausedStateMSec) || abs(lastPlaybackPos - currentPlaybackPos) > AVPlayerIntegrationWrapper.KMinPlaybackPosDriftForPlayingStateMSec) { // We are not in buffering
                        //Check for possibility of occurrence of seek
                        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => tick process possibility of occurrence of seek \(currentRecordTime) - \(lastPlaybackPosRecordTime) = \(currentRecordTime - lastPlaybackPosRecordTime) ---")
                        
                        if (AVPlayerIntegrationWrapper.isPossibleSeek(currpos: currentPlaybackPos, lastPos: lastPlaybackPos, currentRecordTime: currentRecordTime, lastRecInstant: lastPlaybackPosRecordTime)) {
                            if (self?.sessTerminated == true){
                                AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => tick Seek: Forcing restart of session via Seek ---")
                                self?.continueStoppedSession()
                            }
                            
                            if self?.seekState != .START {
                                self?.seekState = .START
                                GenericMMWrapper.shared.reportPlayerSeekStarted()
                            }
                        }
                    } else {
                        AVPlayerIntegrationWrapper.logDebugStatement("--- MM Log => tick process possibility of occurrence of seek playhead drift \(abs(lastPlaybackPos - currentPlaybackPos)) ---")
                    }
                }
                self?.lastPlaybackPos = currentPlaybackPos
                self?.lastPlaybackPosRecordTime = currentRecordTime
            }
        }
    }
    
    
    //ENABLE IMA
    //IMA ADS FUNCTIONALITIES
    #if canImport(MediaMelonIMA)
    @objc public func setMMIMAContext(adLoadingContext: IMAAdsLoader, adDisplay: IMAAVPlayerVideoDisplay?, hasAdTag: Bool) {
        MMIMAAdManager.sharedManager.setIMAAdsContext(context: adLoadingContext, adsDisplay: adDisplay, hasAdTag: hasAdTag)
    }
    #endif
    
    #if canImport(MediaMelonIMAtvOS)
    #if os(tvOS)
    @objc public func setMMIMAContext(adLoadingContext: IMAAdsLoader, adDisplay: IMAAVPlayerVideoDisplay?, hasAdTag: Bool) {
        MMIMAAdManager.sharedManager.setIMAAdsContext(context: adLoadingContext, adsDisplay: adDisplay, hasAdTag: hasAdTag)
    }
    #endif
    #endif
}
