//
//  ChatViewController.swift
//  图灵聊天
//
//
//
//                                          ___                        ___
//     ___                                 /  /\          ___         /  /\
//    /  /\                               /  /::\        /__/\       /  /:/_
//   /  /:/               ___     ___    /  /:/\:\       \  \:\     /  /:/ /\
//  /__/::\              /__/\   /  /\  /  /:/  \:\       \  \:\   /  /:/ /:/_
//  \__\/\:\__           \  \:\ /  /:/ /__/:/ \__\:\  ___  \__\:\ /__/:/ /:/ /\
//     \  \:\/\           \  \:\  /:/  \  \:\ /  /:/ /__/\ |  |:| \  \:\/:/ /:/
//      \__\::/            \  \:\/:/    \  \:\  /:/  \  \:\|  |:|  \  \::/ /:/
//      /__/:/              \  \::/      \  \:\/:/    \  \:\__|:|   \  \:\/:/
//      \__\/                \__\/        \  \::/      \__\::::/     \  \::/
//                                         \__\/           ~~~~       \__\/
//       ___          _____          ___                       ___           ___           ___
//      /  /\        /  /::\        /  /\        ___          /  /\         /__/\         /  /\
//     /  /::\      /  /:/\:\      /  /::\      /  /\        /  /::\        \  \:\       /  /::\
//    /  /:/\:\    /  /:/  \:\    /  /:/\:\    /  /:/       /  /:/\:\        \  \:\     /  /:/\:\
//   /  /:/~/::\  /__/:/ \__\:|  /  /:/~/:/   /__/::\      /  /:/~/::\   _____\__\:\   /  /:/~/::\
//  /__/:/ /:/\:\ \  \:\ /  /:/ /__/:/ /:/___ \__\/\:\__  /__/:/ /:/\:\ /__/::::::::\ /__/:/ /:/\:\
//  \  \:\/:/__\/  \  \:\  /:/  \  \:\/:::::/    \  \:\/\ \  \:\/:/__\/ \  \:\~~\~~\/ \  \:\/:/__\/
//   \  \::/        \  \:\/:/    \  \::/~~~~      \__\::/  \  \::/       \  \:\  ~~~   \  \::/
//    \  \:\         \  \::/      \  \:\          /__/:/    \  \:\        \  \:\        \  \:\
//     \  \:\         \__\/        \  \:\         \__\/      \  \:\        \  \:\        \  \:\
//      \__\/                       \__\/                     \__\/         \__\/         \__\/
//
//
//
//
//
//  Created by Huangjunwei on 15/9/1.
//  Copyright (c) 2015年 codeGlider. All rights reserved.
//

import UIKit
import SafariServices
import Parse
import ParseUI
import Alamofire
import SnapKit
import SVProgressHUD
import Spring
let messageFontSize: CGFloat = 17
let sentDateFontSize:CGFloat = 10
let toolBarMinHeight: CGFloat = 44
let textViewMaxHeight: (portrait: CGFloat, landscape: CGFloat) = (portrait: 272, landscape: 90)


class ChatViewController:UIViewController,UITextViewDelegate,SFSafariViewControllerDelegate {
    //MARK:属性定义
    
    var tableView:UITableView!
    var toolBar: UIToolbar!
    var textView: UITextView!
    var sendButton: UIButton!
    var backGroundImage:UIImageView!
    var rotating = false
    var continuedActivity: NSUserActivity?
    var isFirstEnter = true
    var howMany7DaysBefore:Double = 1

    var messageObjects:[PFObject] = []
    //[[Message(incoming: true, text: "你好，请叫我灵灵，我是主人的贴身小助手!", sentDate: NSDate())]]
    override var inputAccessoryView: UIView! {
        get {
            if toolBar == nil {
                
                toolBar = UIToolbar(frame: CGRectMake(0, 0, 0, toolBarMinHeight-0.5))
                
                textView = InputTextView(frame: CGRectZero)
                textView.backgroundColor = UIColor(white: 250/255, alpha: 1)
                textView.delegate = self
                textView.font = UIFont.systemFontOfSize(messageFontSize)
                textView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 205/255, alpha:1).CGColor
                textView.layer.borderWidth = 0.5
                textView.layer.cornerRadius = 5
                //            textView.placeholder = "Message"
                textView.scrollsToTop = false
                textView.textContainerInset = UIEdgeInsetsMake(4, 3, 3, 3)
                toolBar.addSubview(textView)
                
                sendButton = UIButton(type: UIButtonType.Custom)
                sendButton.enabled = false
                sendButton.titleLabel?.font = UIFont.boldSystemFontOfSize(17)
                sendButton.setTitle("发送", forState: .Normal)
                sendButton.setTitleColor(UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1), forState: .Disabled)
                sendButton.setTitleColor(UIColor(red: 0.05, green: 0.47, blue: 0.91, alpha: 1.0), forState: .Normal)
                sendButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
                sendButton.addTarget(self, action: "sendAction", forControlEvents: UIControlEvents.TouchUpInside)
                toolBar.addSubview(sendButton)
                
                // Auto Layout allows `sendButton` to change width, e.g., for localization.
                textView.snp_makeConstraints{ (make) -> Void in
                    
                    make.left.equalTo(self.toolBar.snp_left).offset(8)
                    make.top.equalTo(self.toolBar.snp_top).offset(7.5)
                    make.right.equalTo(self.sendButton.snp_left).offset(-2)
                    make.bottom.equalTo(self.toolBar.snp_bottom).offset(-8)
                    
                    
                }
                sendButton.snp_makeConstraints{ (make) -> Void in
                    make.right.equalTo(self.toolBar.snp_right)
                    make.bottom.equalTo(self.toolBar.snp_bottom).offset(-4.5)
                    
                }
                
            }
            return toolBar
        }
    }
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    //MARK:生命周期管理
    func initData(howMany7DaysBefore:Double){

        var index = 0
        
        let query:PFQuery = PFQuery(className:"Messages")
        if let user = PFUser.currentUser(){
            query.whereKey("createdBy", equalTo: user)
            query.limit = 1000
            query.whereKey("sentDate", greaterThanOrEqualTo:NSDate(timeIntervalSinceNow: -howMany7DaysBefore*7*24*60*60))
            query.whereKey("sentDate", lessThanOrEqualTo:NSDate(timeIntervalSinceNow: (howMany7DaysBefore - 1.0)*7*24*60*60))
            //            self.messages = [[Message(incoming: true, text: "你好，请叫我灵灵，我是主人的贴身小助手!", sentDate: NSDate())]]
        }
        
        query.orderByAscending("sentDate")
        //query.fromLocalDatastore()
        
        //query.cachePolicy = PFCachePolicy.CacheElseNetwork
        
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            
            if error == nil {
                if howMany7DaysBefore <= 1{
                    
                self.messageObjects = objects as! [PFObject]
                }else{
                self.messageObjects.insertContentsOf(objects as! [PFObject], at: 0)
                    
                }
                if objects?.count == 0 && howMany7DaysBefore == 1{//如果是第一次登陆
                    let message = Message(messageType:messageType.text.rawValue , incoming: true, text: "\(PFUser.currentUser()!.username!),你好!我是你的私人小助手，请叫我灵灵！",contents:"\(PFUser.currentUser()!.username!),你好!我是你的私人小助手，请叫我灵灵！".dataUsingEncoding(NSUTF8StringEncoding)!, sentDate: NSDate())
                    self.saveMessage(message)
               
                    
                }
                
                if howMany7DaysBefore == 0{
                    self.tableView.reloadDataWithAnimate(AnimationDirect.FromRightToLeft, animationTime: 1.0, interval: 0.1)
                }else{
                self.tableView.reloadData()
                }
                        SVProgressHUD.dismiss()
            
            
                if let header = self.tableView.header{
            header.endRefreshing()
        }
            }else{
                print("Error \(error?.userInfo)")
            }
        }
        
        
        
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
       
        
        self.initData(howMany7DaysBefore)
        
        //        tableView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        backGroundImage = UIImageView(image: UIImage(named: "loginBackground"))
       
        self.tableView = UITableView(frame: self.view.bounds, style: UITableViewStyle.Plain)
        self.view.addSubview(self.tableView)
        
        self.tableView.delegate = self
        self.tableView.dataSource  = self
        self.tableView.backgroundView = backGroundImage
        insertBlurView(self.tableView.backgroundView!, style: UIBlurEffectStyle.Light)
        
        tableView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        
        self.tableView.keyboardDismissMode = .Interactive
        self.tableView.estimatedRowHeight = 44
        self.tableView.contentInset = UIEdgeInsets(top:0, left: 0, bottom:toolBarMinHeight, right: 0)
        
        self.tableView.separatorStyle = .None
       let refreshHeader = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction:"refreshTriggered:")
        refreshHeader.ignoredScrollViewContentInsetTop = 18
  refreshHeader.lastUpdatedTimeLabel?.hidden = true
        refreshHeader.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
       tableView.header = refreshHeader
        
       
        self.navigationItem.setLeftBarButtonItem(itemWithImage("exit", highlightImage: "exit_highlight", target: self, action:"exitButtonTapped:"), animated: true)
        self.navigationItem.setRightBarButtonItem(itemWithImage("setting", highlightImage: "setting_highlight", target: self, action:"settingButtonTapped:"), animated: true)
        title = "灵灵"
        
        
        
        
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        //self.myrefreshControl  =  CBStoreHouseRefreshControl()
 
        
        
        // Do any additional setup after loading the view.
    }
    
    func exitButtonTapped(sender:UIButton){
        PFUser.logOut()

        self.navigationController?.popViewControllerAnimated(true)
        
    }
    func settingButtonTapped(sender:UIButton){
        
        
    }
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        self.view.backgroundColor = UIColor.whiteColor()
        if isFirstEnter {
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.Black)
        SVProgressHUD.showWithStatus("加载聊天记录...")
        }
        
        isFirstEnter = false
        
        
    }
    override func viewDidAppear(animated: Bool)  {
        super.viewDidAppear(animated)
//        TRChatRequestManager.sharedManager.requestMessage("今天北京到天津的火车", handler: { (type, message) -> Void in
//            
//            print(type)
//            print((message as! trainMessage).trains)
//            
//         })
        tableView.flashScrollIndicators()
         self.navigationController?.navigationBarHidden = false
 
    }

    //MARK:textView代理方法
    func textViewDidChange(textView: UITextView) {
        updateTextViewHeight()
        sendButton.enabled = textView.hasText()
    }

    
       @available(iOS 9.0, *)
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var currentCellDate:NSDate!
    
    
    //MARK:发送操作及帮助方法
    func saveMessage(message:Message){
        
        let saveObject = PFObject(className: "Messages")
        saveObject["incoming"] = message.incoming
        saveObject["text"] = message.text
        saveObject["sentDate"] = message.sentDate
        saveObject["url"] = message.url
        saveObject["messageType"] = message.messageType
        let file = PFFile(data: message.contents)
        let user = PFUser.currentUser()
        saveObject["createdBy"] = user
        saveObject["contents"] = file
            
            
        
        
        
        
        
        messageObjects.append(saveObject)
        saveObject.pinInBackgroundWithBlock { (success, error) -> Void in
            if success{
                print("消息本地保存成功!")
            }else{
                
                print("消息本地保存失败! \(error)")
                
            }
        }
        saveObject.saveInBackgroundWithBlock { (success, error) -> Void in
            
            if success{
                print("消息云端保存成功!")
            }else{
                
                print("消息云端保存失败! \(error)")
                
            }
        }

        
    }
    func deleteMessage(message:PFObject){
        message.unpinInBackgroundWithBlock { (success, error) -> Void in
            guard  error == nil else{
                print("本地删除失败! \(error?.userInfo)")
                return
                
            }
            print("本地删除成功!")
        
        }
message.deleteInBackgroundWithBlock { (success, error) -> Void in
        guard  error == nil else{
            print("云端删除失败! \(error?.userInfo)")
            return
    
            }
            print("云端删除成功!")
        }
    
    }

    func sendAction() {
        var question = ""
        var answer = ""
    
        
         question = textView.text!
        let data = question.dataUsingEncoding(NSUTF8StringEncoding)!
        
        let message = Message(messageType:messageType.text.rawValue , incoming: false, text:question,contents:data,sentDate: NSDate())
        self.createUserActivity(messageObjects.count - 1, text:question, url: "")
        saveMessage(message)

        
       
        
        
        textView.text = nil
        updateTextViewHeight()
        sendButton.enabled = false
        self.tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths([
            NSIndexPath(forRow:tableView.numberOfRowsInSection(0), inSection:0)
            ], withRowAnimation: .Left)
        self.tableView.endUpdates()
        self.tableViewScrollToBottomAnimated(false)
     TRChatRequestManager.sharedManager.requestMessage(question) { (type, message) -> Void in
        switch (type){
            
        case .text:
            let answer = (message as! textMessage).answer as String
            let messageToSave = Message(messageType:messageType.text.rawValue, incoming: true, text:answer ,contents:answer.dataUsingEncoding(NSUTF8StringEncoding)!, sentDate: NSDate())
            self.saveMessage(messageToSave)
            self.createUserActivity(self.messageObjects.count - 1 ,text:answer, url:"")
            
            break
        case .link:
            
            let answer = (message as! linkMessage).answer as String
            let url =  (message as! linkMessage).url as String
            let urlData = url.dataUsingEncoding(NSUTF8StringEncoding)
            
            let messageToSave = Message(messageType: messageType.link.rawValue,incoming: true, text:answer ,contents:urlData!, sentDate: NSDate())
      
           
           
            self.saveMessage(messageToSave)
            self.createUserActivity(self.messageObjects.count - 1 ,text:answer, url:url)
            
            break
        case .trains:
            let answer = (message as! trainMessage).answer
            let contents = (message as! trainMessage).trains as! AnyObject
            
            let messageToSave = Message(messageType: messageType.trains.rawValue, incoming: true, text: answer,contents:archiveObject(contents), sentDate: NSDate())
            //let messageContents = NSKeyedUnarchiver.unarchiveObjectWithData(messageToSave.contents) as! [trainsType]
            
            self.saveMessage(messageToSave)
            self.createUserActivity(self.messageObjects.count - 1 ,text:answer, url:"")
            
        
            break
        case .news:
            let answer = (message as! newsMessage).answer
            let contents = (message as! newsMessage).news as! AnyObject
            let messageToSave = Message(messageType: messageType.news.rawValue, incoming: true, text: answer,contents:archiveObject(contents), sentDate: NSDate())
            self.saveMessage(messageToSave)
            print(messageToSave)
            self.createUserActivity(self.messageObjects.count - 1 ,text:answer, url:"")
            break
        case .recipes:
            let answer = (message as! newsMessage).answer
            let contents = (message as! newsMessage).news as! AnyObject
            let messageToSave = Message(messageType: messageType.news.rawValue, incoming: true, text: answer,contents:archiveObject(contents), sentDate: NSDate())
            self.saveMessage(messageToSave)
            self.createUserActivity(self.messageObjects.count - 1 ,text:answer, url:"")

            break
        default: break
            
            
        }
        
        self.tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths([
            NSIndexPath(forRow:self.tableView.numberOfRowsInSection(0) , inSection:0)
            ], withRowAnimation:.Left)
        self.tableView.endUpdates()
        self.tableViewScrollToBottomAnimated(false)
        }

        
    }
   
    func createUserActivity(index:Int,text:String,url:String){
        let myActivity = NSUserActivity(activityType: "com.codeGlider.TuringChatMachine.chat")//1
        myActivity.title = "\(text)" // 2
        myActivity.eligibleForSearch = true // 4
        
        myActivity.keywords = Set(arrayLiteral:text) // 5
        self.userActivity = myActivity // 6
        if url != ""{
            self.userActivity?.userInfo = ["index":index]
            self.userActivity?.webpageURL = NSURL(string: url)
        }else{
            self.userActivity?.userInfo = ["index":index]
        }
        myActivity.eligibleForHandoff = false // 7
        myActivity.becomeCurrent() // 8
    }
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        continuedActivity = activity
        if let index = continuedActivity!.userInfo!["index"] as? Int {
            
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow:index, inSection:0), atScrollPosition: .Middle, animated: true)
        }
        
        if let url = continuedActivity?.webpageURL{
            let webVC = SFSafariViewController(URL:url, entersReaderIfAvailable: true)
            webVC.delegate = self
            self.presentViewController(webVC, animated: true, completion: nil)
        }
        super.restoreUserActivityState(activity)
    }
    
    func tableViewScrollToBottomAnimated(animated: Bool) {
        
        
        let numberOfRows = tableView.numberOfRowsInSection(0)
        if numberOfRows > 0 {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow:numberOfRows - 1, inSection: 0), atScrollPosition: .Bottom, animated: animated)
        }
    }
    func updateTextViewHeight() {
        let oldHeight = textView.frame.height
        let maxHeight = UIInterfaceOrientationIsPortrait(interfaceOrientation) ? textViewMaxHeight.portrait : textViewMaxHeight.landscape
        var newHeight = min(textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.max)).height, maxHeight)
        #if arch(x86_64) || arch(arm64)
            newHeight = ceil(newHeight)
            #else
            newHeight = CGFloat(ceilf(newHeight.native))
        #endif
        if newHeight != oldHeight {
            toolBar.frame.size.height = newHeight+8*2-0.5
        }
    }
    //MARK:键盘弹出监控方法
    func keyboardWillShow(notification: NSNotification) {
        
        let userInfo = notification.userInfo as NSDictionary!
        let frameNew = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let insetNewBottom = tableView.convertRect(frameNew, fromView: nil).height
        let insetOld = tableView.contentInset
        let insetChange = insetNewBottom - insetOld.bottom
        let overflow = tableView.contentSize.height - (tableView.frame.height-insetOld.top-insetOld.bottom)
        
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let animations: (() -> Void) = {
            if !(self.tableView.tracking || self.tableView.decelerating) {
                // 根据键盘位置调整Inset
                if overflow > 0 {
                    self.tableView.contentOffset.y += insetChange
                    if self.tableView.contentOffset.y < -insetOld.top {
                        self.tableView.contentOffset.y = -insetOld.top
                    }
                } else if insetChange > -overflow {
                    self.tableView.contentOffset.y += insetChange + overflow
                }
            }
        }
        if duration > 0 {
            let options = UIViewAnimationOptions(rawValue: UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16)) // http://stackoverflow.com/a/18873820/242933
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }
    
    func keyboardDidShow(notification: NSNotification) {
        let userInfo = notification.userInfo as NSDictionary!
        let frameNew = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let insetNewBottom = tableView.convertRect(frameNew, fromView: nil).height
        
        // Inset `tableView` with keyboard
        let contentOffsetY = tableView.contentOffset.y
        tableView.contentInset.bottom = insetNewBottom
        tableView.scrollIndicatorInsets.bottom = insetNewBottom
        // Prevents jump after keyboard dismissal
        if self.tableView.tracking || self.tableView.decelerating {
            tableView.contentOffset.y = contentOffsetY
        }
    }
    
    
    func itemWithImage(image:String,highlightImage:String,target:AnyObject,action:Selector)->UIBarButtonItem
    {
        
        let button = UIButton(type: UIButtonType.Custom)
        button.setBackgroundImage(UIImage(named: image), forState: UIControlState.Normal)
        button.setBackgroundImage(UIImage(named: highlightImage), forState: UIControlState.Highlighted)
        
        button.frame = CGRect(origin: CGPointZero, size: (UIImage(named: image)?.size)!)
        
        button.addTarget(target, action: action, forControlEvents: UIControlEvents.TouchUpInside)
        
        return UIBarButtonItem(customView: button)
    }

    func refreshTriggered(sender:AnyObject){
    
        self.initData(++howMany7DaysBefore)

        
    
    }
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    
}
class InputTextView: UITextView {
    
    
    
}
    //MARK:tableView代理方法
extension ChatViewController:UITableViewDataSource,UITableViewDelegate{
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete{
            deleteMessage(messageObjects[indexPath.row])
            messageObjects.removeAtIndex(indexPath.row)
            
            tableView.reloadData()
            
        }
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        print("Selected At row \(indexPath.row)")
        guard let selectedCell = tableView.cellForRowAtIndexPath(indexPath) as? MessageBubbleTableViewCell else{
            
            return nil
        }
        print("\(selectedCell.url)")
        let url = selectedCell.url
        
        guard url != "" else{
            return nil
        }
        
        print(selectedCell.url)
        let webVC = SFSafariViewController(URL: NSURL(string: url)!, entersReaderIfAvailable: true)
        webVC.delegate = self
        self.presentViewController(webVC, animated: true, completion: nil)
        
        
        
        return nil
    }
     func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        var showSentDate = false
        let object =  messageObjects[indexPath.row]
        
        let message = Message(messageType:object["messageType"] as! String, incoming:object["incoming"] as! Bool, text: object["text"] as! String,contents:(object["contents"] as! PFFile).getData()!, sentDate: object["sentDate"] as! NSDate)
        if indexPath.row == 0{
            currentCellDate = message.sentDate
            showSentDate = true
        }
        let timeInterval = currentCellDate.timeIntervalSinceDate(message.sentDate)
        print(abs(timeInterval))
        
        if abs(timeInterval) > 60*3{
            showSentDate = true
        }
        let cellIdentifier:String
   
        
        if message.messageType == messageType.text.rawValue || message.messageType == messageType.link.rawValue{
            cellIdentifier =  NSStringFromClass(MessageBubbleTableViewCell)
            
           var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! MessageBubbleTableViewCell!
            if cell == nil {
                
                cell = MessageBubbleTableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
                
            }
            cell.configureWithMessage(message,showSentDate:showSentDate)
            currentCellDate = message.sentDate
            cell.backgroundColor = UIColor.clearColor()
           return cell
            
        }else{
            
            cellIdentifier =  NSStringFromClass(MutiMessageTableViewCell)
            
            var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! MutiMessageTableViewCell!
            if cell == nil {
                
                cell = MutiMessageTableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
                
            }
            cell.configureWithMutiMessage(message,showSentDate:showSentDate)
            currentCellDate = message.sentDate
            cell.backgroundColor = UIColor.clearColor()
            return cell
        
        }
      
      
        
    }
    
    
    
     func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
        
    }
     func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if messageObjects.count > 0{
            return messageObjects.count
        }else{
            return 0
        }
    }



}
